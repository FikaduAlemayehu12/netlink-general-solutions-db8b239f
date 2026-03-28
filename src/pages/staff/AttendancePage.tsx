import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { Clock, LogIn, LogOut, Calendar, Timer, PlaneTakeoff, CheckCircle, X, Plus, Users, Download } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/contexts/AuthContext";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import StaffLayout from "@/components/staff/StaffLayout";
import ExecutiveAttendanceView from "@/components/staff/ExecutiveAttendanceView";
import { buildStaffSummaries, exportCSV, exportPDF } from "@/lib/attendance-export";

const LEAVE_TYPES = ["annual", "sick", "personal", "maternity", "paternity", "unpaid"];

// Ethiopian public holidays (approximate dates, updated annually)
const ETHIOPIAN_PUBLIC_HOLIDAYS_2025 = [
  "2025-01-07", // Christmas (Genna)
  "2025-01-19", // Epiphany (Timkat)
  "2025-03-02", // Battle of Adwa
  "2025-04-18", // Good Friday
  "2025-04-20", // Easter
  "2025-05-01", // Labour Day
  "2025-05-05", // Patriots' Victory Day
  "2025-05-28", // Derg Downfall Day
  "2025-09-11", // New Year (Enkutatash)
  "2025-09-27", // Meskel
];

function isPublicHoliday(dateStr: string): boolean {
  const d = dateStr.slice(0, 10);
  // Check current year and next year patterns
  return ETHIOPIAN_PUBLIC_HOLIDAYS_2025.some(h => h.slice(5) === d.slice(5));
}

// Working hours: Mon-Fri 7:30-11:30 & 13:00-23:00, Sat 7:30-11:30
// Returns the number of REGULAR (non-overtime) hours in a clock-in/out session
function calculateRegularHours(clockIn: Date, clockOut: Date): number {
  const day = clockIn.getDay(); // 0=Sun, 6=Sat
  const dateStr = clockIn.toISOString().slice(0, 10);

  // Sunday or public holiday => all overtime
  if (day === 0 || isPublicHoliday(dateStr)) return 0;

  // Define working windows for this day
  type Window = { start: number; end: number };
  let windows: Window[] = [];

  if (day === 6) {
    // Saturday: 7:30 - 11:30
    windows = [{ start: 7.5, end: 11.5 }];
  } else {
    // Mon-Fri: 7:30-11:30, 13:00-23:00
    windows = [{ start: 7.5, end: 11.5 }, { start: 13, end: 23 }];
  }

  const inHour = clockIn.getHours() + clockIn.getMinutes() / 60;
  const outHour = clockOut.getHours() + clockOut.getMinutes() / 60;

  let regularHours = 0;
  for (const w of windows) {
    const overlapStart = Math.max(inHour, w.start);
    const overlapEnd = Math.min(outHour, w.end);
    if (overlapEnd > overlapStart) {
      regularHours += overlapEnd - overlapStart;
    }
  }

  return parseFloat(regularHours.toFixed(2));
}

export default function AttendancePage() {
  const { user, isExecutive } = useAuth();
  const [activeTab, setActiveTab] = useState<"attendance" | "leave" | "executive">("attendance");
  const [todayRecords, setTodayRecords] = useState<any[]>([]);
  const [attendanceHistory, setAttendanceHistory] = useState<any[]>([]);
  const [leaveRequests, setLeaveRequests] = useState<any[]>([]);
  const [profiles, setProfiles] = useState<Record<string, any>>({});
  const [showLeaveForm, setShowLeaveForm] = useState(false);
  const [loading, setLoading] = useState(true);
  const [newLeave, setNewLeave] = useState({ leave_type: "annual", start_date: "", end_date: "", reason: "" });

  useEffect(() => {
    loadProfiles();
    loadAttendance();
    loadLeaves();
  }, []);

  const loadProfiles = async () => {
    const { data } = await supabase.from("profiles").select("user_id, full_name, position");
    const map: Record<string, any> = {};
    (data || []).forEach((p) => { map[p.user_id] = p; });
    setProfiles(map);
  };

  const loadAttendance = async () => {
    if (!user) return;
    const today = new Date().toISOString().split("T")[0];

    // All of today's records (multiple sessions)
    const { data: todayData } = await supabase
      .from("attendance")
      .select("*")
      .eq("user_id", user.id)
      .gte("clock_in", today + "T00:00:00")
      .lte("clock_in", today + "T23:59:59")
      .order("clock_in", { ascending: true });

    setTodayRecords(todayData || []);

    // History
    const { data: history } = await supabase
      .from("attendance")
      .select("*")
      .eq("user_id", user.id)
      .order("clock_in", { ascending: false })
      .limit(50);

    setAttendanceHistory(history || []);
    setLoading(false);
  };

  const loadLeaves = async () => {
    if (!user) return;
    const query = isExecutive
      ? supabase.from("leave_requests").select("*").order("created_at", { ascending: false })
      : supabase.from("leave_requests").select("*").eq("user_id", user.id).order("created_at", { ascending: false });
    const { data } = await query;
    setLeaveRequests(data || []);
  };

  // Can clock in if: no records today, or the latest record has been clocked out
  const latestToday = todayRecords.length > 0 ? todayRecords[todayRecords.length - 1] : null;
  const canClockIn = !latestToday || !!latestToday.clock_out;
  const canClockOut = !!latestToday && !latestToday.clock_out;

  const clockIn = async () => {
    if (!user) return;
    // clock_in defaults to now() on the server; all sessions are tied to today's date
    await supabase.from("attendance").insert({ user_id: user.id });
    loadAttendance();
  };

  const clockOut = async () => {
    if (!latestToday || !user) return;
    const clockInTime = new Date(latestToday.clock_in);
    const now = new Date();

    // Enforce same calendar day: if clock-out crosses midnight, cap at 23:59:59 of clock-in day
    const clockInDate = clockInTime.toISOString().slice(0, 10);
    const nowDate = now.toISOString().slice(0, 10);
    let effectiveClockOut = now;
    if (nowDate !== clockInDate) {
      // Cap at end of clock-in day
      effectiveClockOut = new Date(clockInDate + "T23:59:59");
    }

    const totalHours = parseFloat(((effectiveClockOut.getTime() - clockInTime.getTime()) / 3600000).toFixed(2));
    const regularHours = calculateRegularHours(clockInTime, effectiveClockOut);
    const overtimeHours = parseFloat(Math.max(0, totalHours - regularHours).toFixed(2));

    await supabase.from("attendance").update({
      clock_out: effectiveClockOut.toISOString(),
      work_hours: totalHours,
      overtime_hours: overtimeHours,
    }).eq("id", latestToday.id);

    loadAttendance();
  };

  const submitLeave = async () => {
    if (!newLeave.start_date || !newLeave.end_date || !user) return;
    await supabase.from("leave_requests").insert({
      user_id: user.id,
      leave_type: newLeave.leave_type,
      start_date: newLeave.start_date,
      end_date: newLeave.end_date,
      reason: newLeave.reason,
    });
    setNewLeave({ leave_type: "annual", start_date: "", end_date: "", reason: "" });
    setShowLeaveForm(false);
    loadLeaves();
  };

  const approveLeave = async (leaveId: string, approved: boolean) => {
    if (!user) return;
    await supabase.from("leave_requests").update({
      status: approved ? "approved" : "rejected",
      approved_by: user.id,
      approved_at: new Date().toISOString(),
    }).eq("id", leaveId);
    loadLeaves();
  };

  const totalHoursThisMonth = attendanceHistory
    .filter((a) => new Date(a.clock_in).getMonth() === new Date().getMonth())
    .reduce((sum, a) => sum + (a.work_hours || 0), 0);

  const totalOvertimeThisMonth = attendanceHistory
    .filter((a) => new Date(a.clock_in).getMonth() === new Date().getMonth())
    .reduce((sum, a) => sum + (a.overtime_hours || 0), 0);

  const todayTotalHours = todayRecords.reduce((sum, a) => sum + (a.work_hours || 0), 0);
  const todaySessions = todayRecords.length;

  const STATUS_COLORS: Record<string, string> = {
    pending: "bg-primary/10 text-primary",
    approved: "bg-accent/10 text-accent",
    rejected: "bg-destructive/10 text-destructive",
  };

  return (
    <StaffLayout>
      <div className="max-w-5xl mx-auto space-y-6">
        <div>
          <h1 className="text-2xl font-heading font-bold text-foreground flex items-center gap-2">
            <Clock className="w-6 h-6 text-primary" />HR & Attendance
          </h1>
          <p className="text-muted-foreground text-sm">Track your working hours and manage leave requests</p>
        </div>

        {/* Tab Switch */}
        <div className="flex gap-1 bg-muted p-1 rounded-lg w-fit flex-wrap">
          {(["attendance", "leave", ...(isExecutive ? ["executive" as const] : [])] as const).map((tab) => (
            <button key={tab} onClick={() => setActiveTab(tab as any)}
              className={`px-4 py-2 rounded-md text-sm font-heading font-medium transition-colors ${activeTab === tab ? "bg-card text-foreground shadow-sm" : "text-muted-foreground hover:text-foreground"}`}>
              {tab === "attendance" ? "My Attendance" : tab === "leave" ? "Leave Management" : "All Staff"}
            </button>
          ))}
        </div>

        {activeTab === "attendance" && (
          <div className="space-y-6">
            {/* Clock In/Out */}
            <Card className="border-primary/20">
              <CardContent className="p-6">
                <div className="flex items-center justify-between flex-wrap gap-4">
                  <div>
                    <h3 className="font-heading font-semibold text-foreground">Today's Attendance</h3>
                    <p className="text-sm text-muted-foreground">{new Date().toLocaleDateString("en-US", { weekday: "long", year: "numeric", month: "long", day: "numeric" })}</p>
                    {todaySessions > 0 && (
                      <p className="text-xs text-muted-foreground mt-1">
                        {todaySessions} session{todaySessions > 1 ? "s" : ""} · {todayTotalHours.toFixed(1)}h total
                      </p>
                    )}
                  </div>
                  <div className="flex gap-3">
                    {canClockIn ? (
                      <Button onClick={clockIn} className="gradient-brand text-primary-foreground font-heading gap-2 shadow-glow">
                        <LogIn className="w-4 h-4" />Clock In
                      </Button>
                    ) : canClockOut ? (
                      <Button onClick={clockOut} variant="destructive" className="font-heading gap-2">
                        <LogOut className="w-4 h-4" />Clock Out
                      </Button>
                    ) : null}
                  </div>
                </div>
                {canClockOut && latestToday && (
                  <div className="mt-3 p-3 bg-muted rounded-lg text-sm text-muted-foreground">
                    <Timer className="w-4 h-4 inline mr-1.5" />
                    Clocked in at {new Date(latestToday.clock_in).toLocaleTimeString()}
                  </div>
                )}
                {/* Today's sessions */}
                {todayRecords.filter(r => r.clock_out).length > 0 && (
                  <div className="mt-3 space-y-1">
                    {todayRecords.filter(r => r.clock_out).map((r, i) => (
                      <div key={r.id} className="flex items-center gap-3 text-xs text-muted-foreground bg-muted/50 rounded px-3 py-1.5">
                        <span className="font-heading font-semibold">Session {i + 1}</span>
                        <span>{new Date(r.clock_in).toLocaleTimeString()} → {new Date(r.clock_out).toLocaleTimeString()}</span>
                        <span className="font-semibold">{r.work_hours}h</span>
                        {r.overtime_hours > 0 && <span className="text-gold">+{r.overtime_hours}h OT (2×)</span>}
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-4">
              <Card><CardContent className="p-4">
                <div className="text-2xl font-heading font-bold text-primary">{totalHoursThisMonth.toFixed(1)}h</div>
                <div className="text-xs text-muted-foreground">Hours This Month</div>
              </CardContent></Card>
              <Card><CardContent className="p-4">
                <div className="text-2xl font-heading font-bold text-gold">{totalOvertimeThisMonth.toFixed(1)}h</div>
                <div className="text-xs text-muted-foreground">Overtime</div>
              </CardContent></Card>
              <Card><CardContent className="p-4">
                <div className="text-2xl font-heading font-bold text-accent">{new Set(attendanceHistory.filter((a) => new Date(a.clock_in).getMonth() === new Date().getMonth()).map((a) => new Date(a.clock_in).toLocaleDateString())).size}</div>
                <div className="text-xs text-muted-foreground">Days Worked</div>
              </CardContent></Card>
            </div>

            {/* History - grouped by date */}
            <Card>
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-base font-heading">Recent Attendance</CardTitle>
                  {attendanceHistory.length > 0 && user && (
                    <div className="flex gap-1.5">
                      <Button
                        size="sm"
                        variant="outline"
                        className="gap-1 text-xs"
                        onClick={() => {
                          const summaries = buildStaffSummaries(attendanceHistory, profiles);
                          const mine = summaries.find(s => s.userId === user.id);
                          if (mine) exportCSV(mine);
                        }}
                      >
                        <Download className="w-3 h-3" />CSV
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        className="gap-1 text-xs"
                        onClick={() => {
                          const summaries = buildStaffSummaries(attendanceHistory, profiles);
                          const mine = summaries.find(s => s.userId === user.id);
                          if (mine) exportPDF(mine);
                        }}
                      >
                        <Download className="w-3 h-3" />PDF
                      </Button>
                    </div>
                  )}
                </div>
              </CardHeader>
              <CardContent>
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b border-border">
                        <th className="text-left text-xs font-heading font-semibold text-muted-foreground px-3 py-2">Date</th>
                        <th className="text-left text-xs font-heading font-semibold text-muted-foreground px-3 py-2">Sessions</th>
                        <th className="text-left text-xs font-heading font-semibold text-muted-foreground px-3 py-2">Total Hours</th>
                        <th className="text-left text-xs font-heading font-semibold text-muted-foreground px-3 py-2">Overtime</th>
                        <th className="text-left text-xs font-heading font-semibold text-muted-foreground px-3 py-2">Details</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border">
                      {(() => {
                        // Group attendance records by calendar date
                        const grouped: Record<string, typeof attendanceHistory> = {};
                        attendanceHistory.forEach((a) => {
                          const dateKey = new Date(a.clock_in).toLocaleDateString();
                          if (!grouped[dateKey]) grouped[dateKey] = [];
                          grouped[dateKey].push(a);
                        });
                        return Object.entries(grouped).map(([dateKey, records]) => {
                          const totalHrs = records.reduce((s, r) => s + (r.work_hours || 0), 0);
                          const totalOT = records.reduce((s, r) => s + (r.overtime_hours || 0), 0);
                          const sessions = records.sort((a, b) => new Date(a.clock_in).getTime() - new Date(b.clock_in).getTime());
                          return (
                            <tr key={dateKey} className="hover:bg-muted/30 align-top">
                              <td className="px-3 py-2 text-sm font-medium">{dateKey}</td>
                              <td className="px-3 py-2 text-sm">{sessions.length}</td>
                              <td className="px-3 py-2 text-sm font-semibold">{totalHrs.toFixed(1)}h</td>
                              <td className="px-3 py-2 text-sm text-gold">{totalOT > 0 ? `+${totalOT.toFixed(1)}h` : "—"}</td>
                              <td className="px-3 py-2 text-xs text-muted-foreground space-y-0.5">
                                {sessions.map((s, i) => (
                                  <div key={s.id}>
                                    {new Date(s.clock_in).toLocaleTimeString()} → {s.clock_out ? new Date(s.clock_out).toLocaleTimeString() : "active"}
                                    {s.work_hours ? ` (${s.work_hours}h)` : ""}
                                  </div>
                                ))}
                              </td>
                            </tr>
                          );
                        });
                      })()}
                    </tbody>
                  </table>
                  {attendanceHistory.length === 0 && <p className="text-center py-6 text-muted-foreground text-sm">No attendance records yet</p>}
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {activeTab === "leave" && (
          <div className="space-y-6">
            <div className="flex justify-end">
              <Button onClick={() => setShowLeaveForm(true)} className="gradient-brand text-primary-foreground font-heading gap-2">
                <Plus className="w-4 h-4" />Request Leave
              </Button>
            </div>

            {showLeaveForm && (
              <Card className="border-primary/30">
                <CardHeader className="pb-3">
                  <CardTitle className="font-heading text-base flex items-center justify-between">
                    Request Leave
                    <button onClick={() => setShowLeaveForm(false)} className="text-muted-foreground hover:text-foreground"><X className="w-4 h-4" /></button>
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid sm:grid-cols-3 gap-4">
                    <div className="space-y-1.5">
                      <label className="text-sm font-medium font-heading">Leave Type</label>
                      <select value={newLeave.leave_type} onChange={(e) => setNewLeave((p) => ({ ...p, leave_type: e.target.value }))}
                        className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                        {LEAVE_TYPES.map((t) => <option key={t} value={t}>{t.charAt(0).toUpperCase() + t.slice(1)}</option>)}
                      </select>
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-sm font-medium font-heading">Start Date</label>
                      <Input type="date" value={newLeave.start_date} onChange={(e) => setNewLeave((p) => ({ ...p, start_date: e.target.value }))} />
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-sm font-medium font-heading">End Date</label>
                      <Input type="date" value={newLeave.end_date} onChange={(e) => setNewLeave((p) => ({ ...p, end_date: e.target.value }))} />
                    </div>
                  </div>
                  <div className="space-y-1.5">
                    <label className="text-sm font-medium font-heading">Reason</label>
                    <Textarea rows={3} placeholder="Reason for leave..." value={newLeave.reason} onChange={(e) => setNewLeave((p) => ({ ...p, reason: e.target.value }))} />
                  </div>
                  <div className="flex gap-3">
                    <Button variant="outline" onClick={() => setShowLeaveForm(false)} className="flex-1">Cancel</Button>
                    <Button onClick={submitLeave} className="flex-1 gradient-brand text-primary-foreground font-heading">Submit Request</Button>
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Leave List */}
            <Card>
              <CardHeader className="pb-3"><CardTitle className="text-base font-heading">Leave Requests</CardTitle></CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {leaveRequests.map((lr) => (
                    <div key={lr.id} className="flex items-center gap-4 p-3 bg-muted/50 rounded-lg">
                      <PlaneTakeoff className="w-5 h-5 text-primary flex-shrink-0" />
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 flex-wrap">
                          {isExecutive && <span className="text-sm font-semibold text-foreground">{profiles[lr.user_id]?.full_name}</span>}
                          <Badge variant="secondary">{lr.leave_type}</Badge>
                          <Badge className={STATUS_COLORS[lr.status]}>{lr.status}</Badge>
                        </div>
                        <div className="text-xs text-muted-foreground mt-0.5">
                          {new Date(lr.start_date).toLocaleDateString()} → {new Date(lr.end_date).toLocaleDateString()}
                          {lr.reason && ` · ${lr.reason}`}
                        </div>
                      </div>
                      {isExecutive && lr.status === "pending" && (
                        <div className="flex gap-1.5">
                          <Button size="sm" variant="outline" onClick={() => approveLeave(lr.id, true)} className="text-accent">Approve</Button>
                          <Button size="sm" variant="outline" onClick={() => approveLeave(lr.id, false)} className="text-destructive">Reject</Button>
                        </div>
                      )}
                    </div>
                  ))}
                  {leaveRequests.length === 0 && <p className="text-center py-6 text-muted-foreground text-sm">No leave requests</p>}
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {activeTab === "executive" && isExecutive && (
          <ExecutiveAttendanceView profiles={profiles} />
        )}
      </div>
    </StaffLayout>
  );
}
