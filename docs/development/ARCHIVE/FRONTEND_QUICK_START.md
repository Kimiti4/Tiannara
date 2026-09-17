# Frontend Quick Start Guide

## 🚀 Running the Frontend

```bash
cd tiannara_gui
npm run dev
```

Server starts at: **http://localhost:5176/**

---

## 📦 Available Components

### Import Syntax
```javascript
import { Button, Card, Badge } from "../components";
```

### UI Components

#### Button
```jsx
<Button variant="primary" size="md" onClick={handleClick}>
  Submit
</Button>

// Variants: primary, secondary, success, danger, ghost
// Sizes: sm, md, lg
```

#### Card
```jsx
<Card padding="md">
  <h3>Title</h3>
  <p>Content</p>
</Card>

// Padding: sm, md (default), lg
```

#### Badge
```jsx
<Badge variant="success">Active</Badge>

// Variants: default, success, warning, danger, info
```

#### Input
```jsx
<Input 
  label="Email" 
  value={email} 
  onChange={handleChange}
  placeholder="Enter email..."
/>
```

#### Textarea
```jsx
<Textarea 
  value={text} 
  onChange={handleChange}
  rows={4}
  placeholder="Enter text..."
/>
```

#### LoadingState
```jsx
<LoadingState message="Loading..." size="md" />

// Sizes: sm, md (default), lg
```

#### EmptyState
```jsx
<EmptyState 
  title="No data" 
  description="Try adjusting your filters"
  action={<Button>Refresh</Button>}
/>
```

### Layout Components

#### PageLayout
```jsx
<PageLayout title="Dashboard">
  <YourContent />
</PageLayout>
```

---

## 🎨 Design Tokens

### Colors
- **Primary**: `cyan-500` (#06b6d4)
- **Background**: `slate-950` (#020617)
- **Cards**: `slate-900` (#0f172a)
- **Text**: `white`, `slate-100`, `slate-300`, `slate-400`
- **Success**: `emerald-400` (#34d399)
- **Warning**: `amber-400` (#fbbf24)
- **Error**: `rose-400` (#fb7185)

### Spacing
- Small: `p-3` (12px), `gap-2` (8px)
- Medium: `p-4` (16px), `gap-4` (16px) ← Default
- Large: `p-6` (24px), `gap-6` (24px)

### Typography
- Title: `text-3xl font-bold`
- Heading: `text-lg font-semibold`
- Body: `text-base`
- Small: `text-sm`
- Tiny: `text-xs`

---

## 📄 Page Structure

Every page follows this pattern:

```jsx
export default function YourPage() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [data, setData] = useState(null);

  async function handleSubmit() {
    setLoading(true);
    setError("");
    
    try {
      const res = await fetch("/api/endpoint", { method: "POST" });
      const data = await res.json();
      setData(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <section>
        <h1 className="text-3xl font-bold text-white">Page Title</h1>
        <p className="text-slate-400">Description</p>
      </section>

      {/* Error */}
      {error && (
        <div className="rounded-2xl border border-rose-800/60 bg-rose-950/20 p-4 text-rose-300">
          {error}
        </div>
      )}

      {/* Loading */}
      {loading && <LoadingState message="Processing..." />}

      {/* Content */}
      {!loading && !error && (
        <Card>
          {/* Your content here */}
        </Card>
      )}

      {/* Empty State */}
      {!loading && !error && !data && (
        <EmptyState title="No data" description="Get started by..." />
      )}
    </div>
  );
}
```

---

## 🔗 Navigation

### Adding a New Page

1. **Create page file**: `src/pages/YourPage.jsx`
2. **Add to router**: `src/router.jsx`
   ```javascript
   {
     path: "/your-page",
     element: <PageLayout title="Your Page"><YourPage /></PageLayout>,
   }
   ```
3. **Add to sidebar**: `src/components/layout/Sidebar.jsx`
   ```javascript
   { label: "Your Page", path: "/your-page" }
   ```

---

## 🐛 Debugging

### Common Issues

**Import Error**:
```
Failed to resolve import "../components"
```
**Fix**: Use barrel export:
```javascript
import { Button } from "../components"; // ✅
import Button from "../components/ui/Button"; // Also works
```

**Router Not Working**:
Check `main.jsx` has:
```javascript
import { RouterProvider } from "react-router-dom";
import router from "./router";

<RouterProvider router={router} />
```

**Styles Not Applying**:
Ensure Tailwind is processing:
```bash
npm run build  # Check for errors
```

---

## 📱 Responsive Design

### Breakpoints
- Mobile: `< 768px`
- Tablet: `768px - 1280px`
- Desktop: `> 1280px`

### Usage
```jsx
// Hide on mobile, show on tablet+
<div className="hidden md:block">...</div>

// Responsive grid
<div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4">
  {/* Cards */}
</div>
```

---

## 🧪 Testing

### Manual Testing Checklist
- [ ] Page loads without errors
- [ ] Navigation works (sidebar links)
- [ ] Forms submit correctly
- [ ] Loading states show
- [ ] Error messages display
- [ ] Results render properly
- [ ] Mobile responsive (if implemented)

### Build Test
```bash
npm run build
# Should complete with no errors
```

---

## 📚 Resources

- **Tailwind Docs**: https://tailwindcss.com/docs
- **React Router**: https://reactrouter.com
- **Component Library**: `src/components/index.js`

---

## ✨ Tips

1. **Always use components** instead of inline styles
2. **Follow the page structure** template above
3. **Add loading/error states** for all API calls
4. **Use semantic HTML** (`<section>`, `<header>`, etc.)
5. **Test in browser** after each change

---

**Happy coding!** 🚀
