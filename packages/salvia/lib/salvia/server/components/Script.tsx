import { h } from "preact";

export default function Script({ children, ...props }: any) {
  // If children is a string, inject it as raw HTML to prevent escaping
  if (typeof children === "string") {
    return <script {...props} dangerouslySetInnerHTML={{ __html: children }} />;
  }
  
  // Handle array of strings (e.g. multiple lines)
  if (Array.isArray(children) && children.every(c => typeof c === "string")) {
    return <script {...props} dangerouslySetInnerHTML={{ __html: children.join("") }} />;
  }

  return <script {...props}>{children}</script>;
}
