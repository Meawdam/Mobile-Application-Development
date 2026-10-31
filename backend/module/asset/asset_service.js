const assetRepository = require("./asset_repository");

class AssetService {
    async getAvailableAsset() {
        return await assetRepository.findAllApproved();
    }

    async getAllAsset() {
        return await assetRepository.findAll();
    }

    async getAssetByID(id) {
        const asset = await assetRepository.findById(id);
        if(!asset) {
            const err = new Error("Asset not found");
            err.status = 404;
            throw err;
        }
    }

    async createAsset(ownerId, data) {
        const assetId = await assetsRepository.createAsset({
            owner_id: ownerId,
            ...data
        });
        return {id: assetId, ...data, approval: "pending", status: "ready"}
    }

    async approveAsset(id, {approval, approval_message}) {
        const asset = await assetRepository.findById();
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

        await assetsRepository.deleteAsset(id, owner_id);
    }
}

module.exports = new AssetService();