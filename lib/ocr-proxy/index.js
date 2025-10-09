const express = require("express");
const cors = require("cors");
const multer = require("multer");
const axios = require("axios");
const FormData = require("form-data");

const app = express();
const upload = multer();

app.use(cors({ origin: true }));

app.post("/ocr", upload.single("image"), async (req, res) => {
    try {
        const apiKey = "K83755704588957"; // Reemplaza si tienes otra API Key

        const formData = new FormData();
        formData.append("file", req.file.buffer, "image.png");
        formData.append("language", "spa");
        formData.append("isOverlayRequired", "false");
        formData.append("OCREngine", "2");

        const response = await axios.post("https://api.ocr.space/parse/image", formData, {
            headers: {
                ...formData.getHeaders(),
                apikey: apiKey,
            },
        });

        res.status(200).json(response.data);
    } catch (error) {
        console.error("OCR ERROR:", error.message);
        res.status(500).json({ error: "Error procesando OCR" });
    }
});

exports.api = functions.https.onRequest(app);
