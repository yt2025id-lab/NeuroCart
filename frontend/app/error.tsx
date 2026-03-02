"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div style={{ padding: 40, background: "#070707", color: "white", fontFamily: "monospace" }}>
      <h2 style={{ color: "#f87171" }}>Runtime Error</h2>
      <pre style={{ background: "#111", padding: 16, borderRadius: 8, overflow: "auto", fontSize: 12 }}>
        {error?.message}
        {"\n\n"}
        {error?.stack}
      </pre>
      <button onClick={reset} style={{ marginTop: 16, padding: "8px 16px", background: "#34d399", border: "none", borderRadius: 8, cursor: "pointer" }}>
        Retry
      </button>
    </div>
  );
}
