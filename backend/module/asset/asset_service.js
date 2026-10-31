const assetRepository = require("./asset_repository");

class AssetService {
    async getAvailableAsset(excludedOwnerId) {
        return await assetRepository.findAllApproved(excludedOwnerId);
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
            return_before: normalizedReturnBefore,
        });
        return {
            id: assetId,
            ...data,
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