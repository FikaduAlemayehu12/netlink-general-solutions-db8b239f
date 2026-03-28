import { ReactNode } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";

interface Props { children: ReactNode; }

export default function StaffGuard({ children }: Props) {
  const { user, profile, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen bg-navy flex items-center justify-center">
        <div className="w-10 h-10 border-4 border-cyan-brand/30 border-t-cyan-brand rounded-full animate-spin" />
      </div>
    );
  }

  if (!user) return <Navigate to="/staff/login" replace />;
  return <>{children}</>;
}
