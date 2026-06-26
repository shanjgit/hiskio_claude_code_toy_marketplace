import * as Sentry from "@sentry/react";
import NavigationBar from "@/components/NavigationBar";
import { Button } from "@/components/ui/button";

const AboutContent = () => {
  const throwTestError = () => {
    throw new Error("Sentry test error from About page");
  };

  const captureTestMessage = () => {
    Sentry.captureMessage("Test message from About page", "info");
    alert("Sentry message sent! Check your Sentry dashboard.");
  };

  return (
    <div className="min-h-screen bg-background">
      <NavigationBar />

      <main className="px-[var(--page-padding)] py-6">
        <div className="max-w-md mx-auto space-y-6">
          <h1 className="text-display font-medium text-foreground mb-4">
            About Marketplace
          </h1>
          <p className="text-body text-foreground mb-4">
            Marketplace is your trusted platform for buying and selling authentic pre-owned products.
          </p>
          <p className="text-body text-foreground">
            We connect sellers with buyers in a safe, secure environment where quality and authenticity are guaranteed.
          </p>

          <div className="border border-dashed border-primary/30 rounded-lg p-4 space-y-3">
            <p className="text-xs font-mono text-primary/60 uppercase tracking-wide">
              Sentry Integration Test
            </p>
            <div className="flex gap-3 flex-wrap">
              <Button
                variant="outline"
                size="sm"
                onClick={captureTestMessage}
              >
                Send test message
              </Button>
              <Button
                variant="destructive"
                size="sm"
                onClick={throwTestError}
              >
                Throw test error
              </Button>
            </div>
            <p className="text-xs text-foreground/50">
              "Send test message" captures an info event. "Throw test error" triggers the error boundary and sends an exception.
            </p>
          </div>
        </div>
      </main>
    </div>
  );
};

const About = Sentry.withErrorBoundary(AboutContent, {
  fallback: ({ error, resetError }) => (
    <div className="min-h-screen bg-background flex items-center justify-center px-4">
      <div className="max-w-sm text-center space-y-4">
        <p className="font-mono text-sm text-destructive">Something went wrong</p>
        <p className="text-xs text-foreground/60 font-mono break-all">
          {(error as Error)?.message}
        </p>
        <Button onClick={resetError} variant="outline" size="sm">
          Try again
        </Button>
      </div>
    </div>
  ),
  showDialog: true,
});

export default About;
