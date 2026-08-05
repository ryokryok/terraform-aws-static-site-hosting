import { NavLink, Outlet } from "react-router";
import "./App.css";

const NAV = [
  { to: "/", label: "Home", end: true },
  { to: "/about", label: "About", end: false },
  { to: "/posts", label: "Posts", end: false },
];

export default function App() {
  return (
    <>
      <header className="site-header">
        <nav>
          <ul>
            {NAV.map(({ to, label, end }) => (
              <li key={to}>
                <NavLink to={to} end={end} className={({ isActive }) => (isActive ? "active" : "")}>
                  {label}
                </NavLink>
              </li>
            ))}
          </ul>
        </nav>
      </header>

      <main>
        <Outlet />
      </main>
    </>
  );
}
