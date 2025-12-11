import { h } from "preact";
import Island from "../components/Island.tsx";
import Counter from "../islands/Counter.tsx";

export default function Home({ title }: { title: string }) {
  return (
    <html>
      <head>
        <title>{title}</title>
        <script type="module" src="/assets/javascripts/islands.js"></script>
      </head>
      <body class="p-8">
        <h1 class="text-3xl font-bold mb-4">{title}</h1>
        <p class="mb-4">This is a Server Component (Page).</p>
        <Island name="Counter" component={Counter} />
      </body>
    </html>
  );
}
