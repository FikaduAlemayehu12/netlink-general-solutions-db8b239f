import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "@/contexts/AuthContext";
import StaffGuard from "@/components/staff/StaffGuard";

// Public pages
import Navbar from "./components/Navbar";
import Footer from "./components/Footer";
import ChatBot from "./components/ChatBot";
import Index from "./pages/Index";
import About from "./pages/About";
import Services from "./pages/Services";
import Solutions from "./pages/Solutions";
import Contact from "./pages/Contact";
import Careers from "./pages/Careers";
import Blog from "./pages/Blog";
import Privacy from "./pages/Privacy";
import NotFound from "./pages/NotFound";

// Staff portal pages
import StaffLogin from "./pages/staff/StaffLogin";

import StaffDashboard from "./pages/staff/StaffDashboard";
import PlansPage from "./pages/staff/PlansPage";
import ProjectsPage from "./pages/staff/ProjectsPage";
import PerformancePage from "./pages/staff/PerformancePage";
import NotificationsPage from "./pages/staff/NotificationsPage";
import AdminUsers from "./pages/staff/AdminUsers";
import ProfilePage from "./pages/staff/ProfilePage";
import TeamPage from "./pages/staff/TeamPage";
import TicketsPage from "./pages/staff/TicketsPage";
import AttendancePage from "./pages/staff/AttendancePage";
import MessagesPage from "./pages/staff/MessagesPage";
import SalaryPage from "./pages/staff/SalaryPage";

const queryClient = new QueryClient();

// Layout wrapper for public pages
function PublicLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <Navbar />
      {children}
      <Footer />
      <ChatBot />
    </>
  );
}

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <AuthProvider>
          <Routes>
            {/* ===== PUBLIC WEBSITE ===== */}
            <Route path="/" element={<PublicLayout><Index /></PublicLayout>} />
            <Route path="/about" element={<PublicLayout><About /></PublicLayout>} />
            <Route path="/services" element={<PublicLayout><Services /></PublicLayout>} />
            <Route path="/solutions" element={<PublicLayout><Solutions /></PublicLayout>} />
            <Route path="/contact" element={<PublicLayout><Contact /></PublicLayout>} />
            <Route path="/careers" element={<PublicLayout><Careers /></PublicLayout>} />
            <Route path="/blog" element={<PublicLayout><Blog /></PublicLayout>} />
            <Route path="/privacy" element={<PublicLayout><Privacy /></PublicLayout>} />
            <Route path="/terms" element={<PublicLayout><Privacy /></PublicLayout>} />

            {/* ===== STAFF PORTAL ===== */}
            <Route path="/staff/login" element={<StaffLogin />} />
            
            <Route path="/staff/dashboard" element={<StaffGuard><StaffDashboard /></StaffGuard>} />
            <Route path="/staff/plans" element={<StaffGuard><PlansPage /></StaffGuard>} />
            <Route path="/staff/projects" element={<StaffGuard><ProjectsPage /></StaffGuard>} />
            <Route path="/staff/performance" element={<StaffGuard><PerformancePage /></StaffGuard>} />
            <Route path="/staff/notifications" element={<StaffGuard><NotificationsPage /></StaffGuard>} />
            <Route path="/staff/team" element={<StaffGuard><TeamPage /></StaffGuard>} />
            <Route path="/staff/tickets" element={<StaffGuard><TicketsPage /></StaffGuard>} />
            <Route path="/staff/attendance" element={<StaffGuard><AttendancePage /></StaffGuard>} />
            <Route path="/staff/profile" element={<StaffGuard><ProfilePage /></StaffGuard>} />
            <Route path="/staff/messages" element={<StaffGuard><MessagesPage /></StaffGuard>} />
            <Route path="/staff/salary" element={<StaffGuard><SalaryPage /></StaffGuard>} />
            <Route path="/staff/settings" element={<StaffGuard><ProfilePage /></StaffGuard>} />
            <Route path="/staff/admin/users" element={<StaffGuard><AdminUsers /></StaffGuard>} />

            {/* Legacy routes */}
            <Route path="/admin/users" element={<StaffGuard><AdminUsers /></StaffGuard>} />

            <Route path="*" element={<NotFound />} />
          </Routes>
        </AuthProvider>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
