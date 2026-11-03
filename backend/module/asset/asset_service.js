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

    async getAssetById(id) {
        const asset = await assetRepository.findById(id);
        if(!asset) {
            const err = new Error("Asset not found");
            err.status = 404;
            throw err;
        }
        return asset;
    }

    async createAsset(ownerId, data) {
        const price = Number(data.price);
        if (
            data.price === undefined ||
            data.price === null ||
            data.price === "" ||
            !Number.isSafeInteger(price) ||
            price < 0 ||
            price > 2147483647 ||
            !/^\d+$/.test(String(data.price))
        ) {
            const err = new Error("price must be a non-negative whole number within the database range");
            err.status = 400;
            throw err;
        }
        if (
            typeof data.pickup_point !== "string" ||
            !data.pickup_point.trim() ||
            data.pickup_point.trim().length > 255
        ) {
            const err = new Error("pickup_point is required");
            err.status = 400;
            throw err;
        }

        const dateParts =
            typeof data.return_before === "string"
                ? /^(\d{4})-(\d{1,2})-(\d{1,2})$/.exec(data.return_before)
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