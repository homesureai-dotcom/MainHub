import {initializeApp, getApps} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

if (getApps().length === 0) {
  initializeApp();
}

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const PHONE_REGEX = /^[+\d\s().-]{7,20}$/;
const ALLOWED_TYPES = new Set(["general", "product", "partnership"]);
const ALLOWED_ORIGINS = [
  "https://homesureai.com",
  "https://www.homesureai.com",
  "https://homesure-marketing.web.app",
  "https://homesure-marketing.firebaseapp.com",
  "https://homesureai-51893.web.app",
  "https://homesureai-51893.firebaseapp.com",
  "https://homesure-marketing--marketing-preview-dh33u8tn.web.app",
];

interface EnquiryRequestBody {
  name?: unknown;
  email?: unknown;
  phone?: unknown;
  enquiryType?: unknown;
  message?: unknown;
  consent?: unknown;
  honeypot?: unknown;
  elapsedMs?: unknown;
}

/**
 * Validated, spam-protected HTTP Cloud Function for public contact enquiries.
 */
export const submitContactEnquiry = onRequest(
  {
    region: "asia-south1",
    cors: ALLOWED_ORIGINS,
    maxInstances: 5,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({error: "Method not allowed."});
      return;
    }

    const body = (req.body ?? {}) as EnquiryRequestBody;

    // Honeypot and timing spam guards
    if (typeof body.honeypot === "string" && body.honeypot.trim().length > 0) {
      res.status(400).json({error: "Invalid submission."});
      return;
    }
    if (typeof body.elapsedMs === "number" && body.elapsedMs < 1200) {
      res.status(400).json({error: "Submission sent too quickly."});
      return;
    }

    const name = typeof body.name === "string" ? body.name.trim() : "";
    const email = typeof body.email === "string" ? body.email.trim() : "";
    const phone = typeof body.phone === "string" ? body.phone.trim() : "";
    const enquiryType =
      typeof body.enquiryType === "string" ? body.enquiryType.trim() : "";
    const message = typeof body.message === "string" ? body.message.trim() : "";
    const consent = body.consent === true;

    if (name.length < 2 || name.length > 120) {
      res.status(400).json({error: "Name must be between 2 and 120 chars."});
      return;
    }
    if (!EMAIL_REGEX.test(email) || email.length > 180) {
      res.status(400).json({error: "Valid email address is required."});
      return;
    }
    if (phone.length > 0 && !PHONE_REGEX.test(phone)) {
      res.status(400).json({error: "Phone format is invalid."});
      return;
    }
    if (!ALLOWED_TYPES.has(enquiryType)) {
      res.status(400).json({error: "Invalid enquiry type."});
      return;
    }
    if (message.length < 12 || message.length > 2000) {
      res.status(400).json({error: "Message must be 12 to 2000 chars."});
      return;
    }
    if (!consent) {
      res.status(400).json({error: "Consent is required."});
      return;
    }

    const db = getFirestore();
    const referenceId = `HS-${Date.now().toString(36).toUpperCase()}`;

    try {
      await db.collection("contact_enquiries").add({
        referenceId,
        name,
        email: email.toLowerCase(),
        phone: phone || null,
        enquiryType,
        message,
        consent: true,
        source: "homesureai.com",
        createdAt: FieldValue.serverTimestamp(),
      });
    } catch (err) {
      const errorMessage =
        err instanceof Error ? err.message : "Unknown Firestore error";
      logger.error("Failed to record public contact enquiry", {
        referenceId,
        enquiryType,
        errorMessage,
      });
      res.status(500).json({
        error: "Unable to record your enquiry right now. Please try again.",
      });
      return;
    }

    logger.info("Public contact enquiry recorded", {
      referenceId,
      enquiryType,
    });

    res.status(201).json({ok: true, referenceId});
  },
);
