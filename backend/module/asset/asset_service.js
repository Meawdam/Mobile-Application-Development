const assetRepository = require("./asset_repository");
const {
    MAX_ASSET_AMOUNT_CENTS,
    amountCentsToNumber,
    formatAmountCents,
    parseAmountCents,
} = require("../../utils/money_utils");

function normalizeAsset(asset) {
    if (!asset) return asset;
    return {
        ...asset,
        down_payment:
            asset.down_payment === null || asset.down_payment === undefined
                ? asset.down_payment
                : Number(asset.down_payment),
        price:
            asset.price === null || asset.price === undefined
                ? asset.price
                : Number(asset.price),
    };
}

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
        const assets = await assetRepository.findAllApproved(
            excludedOwnerId,
            normalizedSearchTerm,
        );
        return assets.map(normalizeAsset);
    }

    async getAllAsset() {
        return (await assetRepository.findAll()).map(normalizeAsset);
    }

    async getMyAssets(ownerId) {
        return (await assetRepository.findByOwnerId(ownerId)).map(normalizeAsset);
    }

    async getAssetById(id, viewer) {
        const asset = await assetRepository.findByIdForViewer(
            id,
            viewer?.id,
            viewer?.role,
        );
        if(!asset) {
            const err = new Error("Asset not found");
            err.status = 404;
            throw err;
        }
        return normalizeAsset(asset);
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

    _validateAssetAmount(value, fieldName) {
        const amountCents = parseAmountCents(value);
        if (
            amountCents === null ||
            amountCents > MAX_ASSET_AMOUNT_CENTS
        ) {
            const err = new Error(
                `${fieldName} must be a non-negative amount with at most 2 decimal places and within the database range`,
            );
            err.status = 400;
            throw err;
        }
        return formatAmountCents(amountCents);
    }

    _validatePrice(priceRaw) {
        return this._validateAssetAmount(priceRaw, "price");
    }

    _validateDownPayment(downPaymentRaw) {
        return this._validateAssetAmount(downPaymentRaw, "down_payment");
    }

    async createAsset(ownerId, data) {
        const price = this._validatePrice(data.price);
        const downPayment = this._validateDownPayment(data.down_payment);
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
            down_payment: downPayment,
            pickup_point: data.pickup_point.trim(),
            return_before: normalizedReturnBefore,
        });
        return {
            id: assetId,
            ...data,
            price: amountCentsToNumber(parseAmountCents(price)),
            down_payment: amountCentsToNumber(parseAmountCents(downPayment)),
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
        const downPayment = this._validateDownPayment(data.down_payment);
        const normalizedReturnBefore = this._validateReturnBefore(data.return_before);
        const payload = {
            name: data.name.trim(),
            description: data.description.trim(),
            down_payment: downPayment,
            price,
            pickup_point: data.pickup_point.trim(),
            return_before: normalizedReturnBefore,
        };

        const updated = await assetRepository.updateAsset(id, ownerId, payload);
        if (!updated) {
            const err = new Error("Asset is no longer available for editing");
            err.status = 409;
            throw err;
        }
        return {
            id: Number(id),
            ...payload,
            down_payment: amountCentsToNumber(parseAmountCents(downPayment)),
            price: amountCentsToNumber(parseAmountCents(price)),
            status: asset.status,
            approval: asset.approval,
        };
    }

    async approveAsset(id, adminId, {approval, approval_message}) {
        if (!["approved", "not approve"].includes(approval)) {
            const err = new Error("Approval status must be approved or not approve");
            err.status = 400;
            throw err;
        }
        const approvalMessage =
            typeof approval_message === "string" ? approval_message.trim() : "";
        if (approval === "not approve" && !approvalMessage) {
            const err = new Error("A rejection reason is required");
            err.status = 400;
            throw err;
        }
        if (approvalMessage.length > 500) {
            const err = new Error("Approval message must not exceed 500 characters");
            err.status = 400;
            throw err;
        }

        const asset = await assetRepository.findById(id);
         if(!asset) {
            const err = new Error("Asset not found");
            err.status = 404;
            throw err;
        }

        const updated = await assetRepository.updateApproval(
            id,
            asset.owner_id,
            adminId,
            approval,
            approvalMessage || null,
        );
        if (!updated) {
            const err = new Error("Asset approval status could not be updated");
            err.status = 409;
            throw err;
        }
        return { id: Number(id), approval, approval_message: approvalMessage || null }
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
        if (asset.status === "borrowed") {
            const err = new Error("Cannot delete an asset while it is borrowed");
            err.status = 409;
            throw err;
        }

        const deleted = await assetRepository.deleteAsset(id, owner_id);
        if (!deleted) {
            const err = new Error("Asset could not be deleted");
            err.status = 409;
            throw err;
        }
        return { id };
    }
}

module.exports = new AssetService();
