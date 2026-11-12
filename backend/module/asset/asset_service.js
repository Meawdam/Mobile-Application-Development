const assetRepository = require("./asset_repository");

class AssetService {
    async getAvailableAsset(excludedOwnerId, searchTerm) {
        if (searchTerm !== undefined && typeof searchTerm !== "string") {
            const err = new Error("q must be a string");
            err.status = 400;
            throw err;
        }
        const normalizedSearchTerm = searchTerm?.trim();
        if (normalizedSearchTerm && normalizedSearchTerm.length > 100) {
            const err = new Error("q must not exceed 100 characters");
            err.status = 400;
            throw err;
        }
        return await assetRepository.findAllApproved(
            excludedOwnerId,
            normalizedSearchTerm,
        );
    }

    async getAllAsset() {
        return await assetRepository.findAll();
    }

    async getMyAssets(ownerId) {
        return await assetRepository.findByOwnerId(ownerId);
    }

    async getAssetById(id) {
        const asset = await assetRepository.findById(id);
        if(!asset) {
            const err = new Error("Asset not found");
            err.status = 404;
            throw err;
        }
        return asset;
    }

    _validateReturnBefore(returnBeforeRaw) {
        const dateParts =
            typeof returnBeforeRaw === "string"
                ? /^(\d{4})-(\d{1,2})-(\d{1,2})$/.exec(returnBeforeRaw)
                : null;
        if (!dateParts) {
            const err = new Error("return_before must be a valid date today or later");
            err.status = 400;
            throw err;
        }

        const [, year, month, day] = dateParts;
        const returnBefore = new Date(
            Date.UTC(Number(year), Number(month) - 1, Number(day)),
        );
        const normalizedReturnBefore = returnBefore.toISOString().slice(0, 10);
        const today = new Date().toISOString().slice(0, 10);
        if (
            Number.isNaN(returnBefore.getTime()) ||
            normalizedReturnBefore !==
                `${year}-${month.padStart(2, "0")}-${day.padStart(2, "0")}` ||
            normalizedReturnBefore < today
        ) {
            const err = new Error("return_before must be a valid date today or later");
            err.status = 400;
            throw err;
        }
        return normalizedReturnBefore;
    }

    _validatePrice(priceRaw) {
        const price = Number(priceRaw);
        if (
            priceRaw === undefined ||
            priceRaw === null ||
            priceRaw === "" ||
            !Number.isSafeInteger(price) ||
            price < 0 ||
            price > 2147483647 ||
            !/^\d+$/.test(String(priceRaw))
        ) {
            const err = new Error("price must be a non-negative whole number within the database range");
            err.status = 400;
            throw err;
        }
        return price;
    }

    async createAsset(ownerId, data) {
        const price = this._validatePrice(data.price);
        if (
            typeof data.pickup_point !== "string" ||
            !data.pickup_point.trim() ||
            data.pickup_point.trim().length > 255
        ) {
            const err = new Error("pickup_point is required");
            err.status = 400;
            throw err;
        }

        const normalizedReturnBefore = this._validateReturnBefore(data.return_before);

        const assetId = await assetRepository.createAsset({
            owner_id: ownerId,
            ...data,
            price,
            pickup_point: data.pickup_point.trim(),
            return_before: normalizedReturnBefore,
        });
        return {
            id: assetId,
            ...data,
            price,
            pickup_point: data.pickup_point.trim(),
            return_before: normalizedReturnBefore,
            approval: "pending",
            status: "ready",
        };
    }

    async updateAsset(id, ownerId, data) {
        const asset = await assetRepository.findById(id);
        if (!asset) {
            const err = new Error("Asset not found");
            err.status = 404;
            throw err;
        }
        if (asset.owner_id !== ownerId) {
            const err = new Error("Forbidden: You are not the owner of this asset");
            err.status = 403;
            throw err;
        }
        if (asset.status === "borrowed") {
            const err = new Error("Cannot edit an asset that is currently borrowed");
            err.status = 400;
            throw err;
        }

        if (
            typeof data.name !== "string" ||
            !data.name.trim() ||
            typeof data.description !== "string" ||
            !data.description.trim() ||
            data.down_payment === undefined ||
            data.down_payment === "" ||
            typeof data.pickup_point !== "string" ||
            !data.pickup_point.trim()
        ) {
            const err = new Error(
                "name, description, down_payment, price, pickup_point, and return_before are required",
            );
            err.status = 400;
            throw err;
        }

        const price = this._validatePrice(data.price);
        const normalizedReturnBefore = this._validateReturnBefore(data.return_before);
        const payload = {
            name: data.name.trim(),
            description: data.description.trim(),
            down_payment: data.down_payment,
            price,
            pickup_point: data.pickup_point.trim(),
            return_before: normalizedReturnBefore,
        };

        await assetRepository.updateAsset(id, ownerId, payload);
        return {
            id: Number(id),
            ...payload,
            status: asset.status,
            approval: asset.approval,
        };
    }

    async approveAsset(id, {approval, approval_message}) {
        if (!["approved", "not approve"].includes(approval)) {
            const err = new Error("Approval status must be approved or not approve");
            err.status = 400;
            throw err;
        }

        const asset = await assetRepository.findById(id);
         if(!asset) {
            const err = new Error("Asset not found");
            err.status = 404;
            throw err;
        }

        await assetRepository.updateApproval(id, approval, approval_message);
        return { id, approval, approval_message}
    }

    async deleteAsset(id, owner_id) {
        const asset = await assetRepository.findById(id);
        if(!asset) {
            const err = new Error("Asset not found");
            err.status = 404;
            throw err;
        }

        if(asset.owner_id !== owner_id) {
            const err = new Error("Forbidden: You are not the owner of this asset");
            err.status = 403;
            throw err;
        }

        await assetRepository.deleteAsset(id, owner_id);
        return { id };
    }
}

module.exports = new AssetService();