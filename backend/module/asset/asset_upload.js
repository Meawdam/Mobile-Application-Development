const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const multer = require("multer");

const uploadDirectory = path.join(__dirname, "../../upload");
const maxImageSize = 5 * 1024 * 1024;
const allowedImageTypes = {
  "image/jpeg": { extension: ".jpg", signature: (buffer) => buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff },
  "image/png": { extension: ".png", signature: (buffer) => buffer.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) },
  "image/gif": { extension: ".gif", signature: (buffer) => ["GIF87a", "GIF89a"].includes(buffer.toString("ascii", 0, 6)) },
  "image/webp": { extension: ".webp", signature: (buffer) => buffer.toString("ascii", 0, 4) === "RIFF" && buffer.toString("ascii", 8, 12) === "WEBP" },
};

fs.mkdirSync(uploadDirectory, { recursive: true });

const upload = multer({
  storage: multer.diskStorage({
    destination: uploadDirectory,
    filename: (req, file, callback) => {
      const imageType = allowedImageTypes[file.mimetype];
      callback(null, `${crypto.randomUUID()}${imageType.extension}`);
    },
  }),
  limits: {
    fileSize: maxImageSize,
    files: 1,
    fields: 3,
  },
  fileFilter: (req, file, callback) => {
    if (!allowedImageTypes[file.mimetype]) {
      const error = new Error("Only JPEG, PNG, GIF, and WebP images are allowed");
      error.status = 400;
      callback(error);
      return;
    }
    callback(null, true);
  },
}).single("image");

function removeFile(filePath) {
  return fs.promises.unlink(filePath).catch((error) => {
    if (error.code !== "ENOENT") {
      throw error;
    }
  });
}

function uploadAssetImage(req, res, next) {
  upload(req, res, async (error) => {
    if (error) {
      if (error instanceof multer.MulterError && error.code === "LIMIT_FILE_SIZE") {
        return res.status(413).json({ message: "Image must not exceed 5 MB" });
      }
      if (error instanceof multer.MulterError) {
        return res.status(400).json({ message: error.message });
      }
      if (error.status === 400) {
        return res.status(400).json({ message: error.message });
      }
      return next(error);
    }

    if (!req.file) {
      return res.status(400).json({ message: "An image file is required" });
    }

    try {
      const fileHandle = await fs.promises.open(req.file.path, "r");
      const signature = Buffer.alloc(12);
      try {
        await fileHandle.read(signature, 0, signature.length, 0);
      } finally {
        await fileHandle.close();
      }

      if (!allowedImageTypes[req.file.mimetype].signature(signature)) {
        await removeFile(req.file.path);
        return res.status(400).json({ message: "The uploaded file is not a valid supported image" });
      }
      next();
    } catch (validationError) {
      try {
        await removeFile(req.file.path);
      } catch (cleanupError) {
        console.error("Failed to remove invalid uploaded image:", cleanupError);
      }
      next(validationError);
    }
  });
}

module.exports = { uploadAssetImage, removeFile };
