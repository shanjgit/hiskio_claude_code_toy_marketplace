import * as Sentry from "@sentry/react";
import { createRoot } from 'react-dom/client'
import App from './App.tsx'
import './index.css'

Sentry.init({
  dsn: "https://b9e4688731dda423a5a6f82e29e603d9@o4511630611316736.ingest.us.sentry.io/4511630626390016",
  environment: import.meta.env.MODE,
  integrations: [
    Sentry.browserTracingIntegration(),
    Sentry.replayIntegration(),
  ],
  tracesSampleRate: 1.0,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
});

createRoot(document.getElementById("root")!).render(<App />);
