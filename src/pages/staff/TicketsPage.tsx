import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Ticket, Plus, X, MessageCircle, Clock, AlertTriangle, CheckCircle, Filter, CalendarIcon, UserPlus } from "lucide-react";
import { format } from "date-fns";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/contexts/AuthContext";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { cn } from "@/lib/utils";
import StaffLayout from "@/components/staff/StaffLayout";

const CATEGORIES = ["Network", "Server", "Software", "Hardware", "General"];
const PRIORITIES = ["low", "medium", "high", "critical"];
const STATUSES = ["open", "in_progress", "resolved", "closed"];

const PRIORITY_COLORS: Record<string, string> = {
  low: "bg-muted text-muted-foreground",
  medium: "bg-primary/10 text-primary",
  high: "bg-destructive/10 text-destructive",
  critical: "bg-destructive text-destructive-foreground",
};

const STATUS_ICONS: Record<string, typeof Clock> = {
  open: Clock,
  in_progress: AlertTriangle,
  resolved: CheckCircle,
  closed: CheckCircle,
};

export default function TicketsPage() {
  const { user, isExecutive, isCeo } = useAuth();
  const [tickets, setTickets] = useState<any[]>([]);
  const [profiles, setProfiles] = useState<Record<string, any>>({});
  const [profilesList, setProfilesList] = useState<any[]>([]);
  const [showCreate, setShowCreate] = useState(false);
  const [creating, setCreating] = useState(false);
  const [selectedTicket, setSelectedTicket] = useState<any>(null);
  const [comments, setComments] = useState<any[]>([]);
  const [newComment, setNewComment] = useState("");
  const [filterStatus, setFilterStatus] = useState("all");
  const [loading, setLoading] = useState(true);
  const [showAssign, setShowAssign] = useState(false);
  const [newTicket, setNewTicket] = useState({ title: "", description: "", category: "General", priority: "medium", due_date: undefined as Date | undefined });

  useEffect(() => {
    loadTickets();
    loadProfiles();

    const channel = supabase
      .channel("tickets-realtime")
      .on("postgres_changes", { event: "*", schema: "public", table: "support_tickets" }, () => loadTickets())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, []);

  const loadProfiles = async () => {
    const { data } = await supabase.from("profiles").select("user_id, full_name, position, avatar_url");
    const map: Record<string, any> = {};
    (data || []).forEach((p) => { map[p.user_id] = p; });
    setProfiles(map);
    setProfilesList(data || []);
  };

  const loadTickets = async () => {
    const { data } = await supabase.from("support_tickets").select("*").order("created_at", { ascending: false });
    setTickets(data || []);
    setLoading(false);
  };

  const loadComments = async (ticketId: string) => {
    const { data } = await supabase.from("ticket_comments").select("*").eq("ticket_id", ticketId).order("created_at");
    setComments(data || []);
  };

  const createTicket = async () => {
    if (!newTicket.title || !newTicket.description || !user) return;
    setCreating(true);
    await supabase.from("support_tickets").insert({
      title: newTicket.title,
      description: newTicket.description,
      category: newTicket.category,
      priority: newTicket.priority,
      created_by: user.id,
      due_date: newTicket.due_date ? format(newTicket.due_date, "yyyy-MM-dd") : null,
    });
    setNewTicket({ title: "", description: "", category: "General", priority: "medium", due_date: undefined });
    setShowCreate(false);
    setCreating(false);
    loadTickets();
  };

  const updateTicketStatus = async (ticketId: string, status: string) => {
    const updates: any = { status };
    if (status === "resolved") updates.resolved_at = new Date().toISOString();
    if (status === "closed") updates.closed_at = new Date().toISOString();
    await supabase.from("support_tickets").update(updates).eq("id", ticketId);
    if (selectedTicket?.id === ticketId) setSelectedTicket({ ...selectedTicket, status, ...updates });
    loadTickets();
  };

  const assignTicket = async (ticketId: string, assigneeId: string) => {
    await supabase.from("support_tickets").update({ assigned_to: assigneeId, status: "in_progress" }).eq("id", ticketId);
    // Notify assignee
    if (assigneeId !== user?.id) {
      await supabase.from("notifications").insert({
        user_id: assigneeId,
        type: "task",
        title: "Ticket assigned to you",
        message: selectedTicket?.title || "A support ticket has been assigned to you",
        related_id: ticketId,
      });
    }
    setShowAssign(false);
    loadTickets();
    if (selectedTicket?.id === ticketId) {
      setSelectedTicket({ ...selectedTicket, assigned_to: assigneeId, status: "in_progress" });
    }
  };

  const addComment = async () => {
    if (!newComment.trim() || !selectedTicket || !user) return;
    await supabase.from("ticket_comments").insert({
      ticket_id: selectedTicket.id,
      author_id: user.id,
      content: newComment,
    });
    setNewComment("");
    loadComments(selectedTicket.id);
  };

  const openTicket = (ticket: any) => {
    setSelectedTicket(ticket);
    loadComments(ticket.id);
    setShowAssign(false);
  };

  const canAssign = (ticket: any) => isCeo || isExecutive || ticket.created_by === user?.id;

  const filteredTickets = filterStatus === "all" ? tickets : tickets.filter((t) => t.status === filterStatus);

  return (
    <StaffLayout>
      <div className="max-w-6xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between flex-wrap gap-3">
          <div>
            <h1 className="text-2xl font-heading font-bold text-foreground flex items-center gap-2">
              <Ticket className="w-6 h-6 text-primary" />IT Support Tickets
            </h1>
            <p className="text-muted-foreground text-sm">Submit and track internal support requests</p>
          </div>
          <Button onClick={() => setShowCreate(true)} className="gradient-brand text-primary-foreground font-heading gap-2 shadow-glow">
            <Plus className="w-4 h-4" />New Ticket
          </Button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {[
            { label: "Open", count: tickets.filter((t) => t.status === "open").length, color: "text-primary" },
            { label: "In Progress", count: tickets.filter((t) => t.status === "in_progress").length, color: "text-gold" },
            { label: "Resolved", count: tickets.filter((t) => t.status === "resolved").length, color: "text-accent" },
            { label: "Closed", count: tickets.filter((t) => t.status === "closed").length, color: "text-muted-foreground" },
          ].map((s) => (
            <Card key={s.label} className="cursor-pointer hover:shadow-card transition-shadow" onClick={() => setFilterStatus(s.label.toLowerCase().replace(" ", "_"))}>
              <CardContent className="p-4">
                <div className={`text-2xl font-heading font-bold ${s.color}`}>{s.count}</div>
                <div className="text-xs text-muted-foreground">{s.label}</div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Filter */}
        <div className="flex items-center gap-2 flex-wrap">
          <Filter className="w-4 h-4 text-muted-foreground" />
          {["all", ...STATUSES].map((s) => (
            <button key={s} onClick={() => setFilterStatus(s)}
              className={`px-3 py-1.5 rounded-full text-xs font-heading font-medium transition-colors ${filterStatus === s ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground hover:bg-muted/80"}`}>
              {s === "all" ? "All" : s.replace("_", " ").replace(/^\w/, (c) => c.toUpperCase())}
            </button>
          ))}
        </div>

        {/* Create Form */}
        <AnimatePresence>
          {showCreate && (
            <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: "auto" }} exit={{ opacity: 0, height: 0 }}>
              <Card className="border-primary/30 shadow-card">
                <CardHeader className="pb-3">
                  <CardTitle className="font-heading text-base flex items-center justify-between">
                    Create Support Ticket
                    <button onClick={() => setShowCreate(false)} className="text-muted-foreground hover:text-foreground"><X className="w-4 h-4" /></button>
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid sm:grid-cols-2 gap-4">
                    <div className="space-y-1.5 sm:col-span-2">
                      <label className="text-sm font-medium font-heading text-foreground">Title</label>
                      <Input placeholder="Brief description of the issue" value={newTicket.title} onChange={(e) => setNewTicket((p) => ({ ...p, title: e.target.value }))} />
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-sm font-medium font-heading text-foreground">Category</label>
                      <select value={newTicket.category} onChange={(e) => setNewTicket((p) => ({ ...p, category: e.target.value }))}
                        className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                        {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
                      </select>
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-sm font-medium font-heading text-foreground">Priority</label>
                      <select value={newTicket.priority} onChange={(e) => setNewTicket((p) => ({ ...p, priority: e.target.value }))}
                        className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                        {PRIORITIES.map((p) => <option key={p} value={p}>{p.charAt(0).toUpperCase() + p.slice(1)}</option>)}
                      </select>
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-sm font-medium font-heading text-foreground">Due Date</label>
                      <Popover>
                        <PopoverTrigger asChild>
                          <Button variant="outline" className={cn("w-full justify-start text-left", !newTicket.due_date && "text-muted-foreground")}>
                            <CalendarIcon className="w-4 h-4 mr-2" />
                            {newTicket.due_date ? format(newTicket.due_date, "MMM d, yyyy") : "Select due date"}
                          </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0" align="start">
                          <Calendar mode="single" selected={newTicket.due_date} onSelect={(d) => setNewTicket(p => ({ ...p, due_date: d }))} className={cn("p-3 pointer-events-auto")} />
                        </PopoverContent>
                      </Popover>
                    </div>
                    <div className="space-y-1.5 sm:col-span-2">
                      <label className="text-sm font-medium font-heading text-foreground">Description</label>
                      <Textarea rows={4} placeholder="Detailed description of your issue..." value={newTicket.description} onChange={(e) => setNewTicket((p) => ({ ...p, description: e.target.value }))} />
                    </div>
                  </div>
                  <div className="flex gap-3">
                    <Button variant="outline" onClick={() => setShowCreate(false)} className="flex-1">Cancel</Button>
                    <Button onClick={createTicket} disabled={creating} className="flex-1 gradient-brand text-primary-foreground font-heading">
                      {creating ? "Submitting…" : "Submit Ticket"}
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Ticket List + Detail */}
        <div className="grid lg:grid-cols-5 gap-6">
          {/* List */}
          <div className="lg:col-span-3 space-y-2">
            {loading ? (
              <div className="space-y-3">{[1, 2, 3, 4].map((i) => <div key={i} className="h-20 bg-muted rounded-xl animate-pulse" />)}</div>
            ) : filteredTickets.length === 0 ? (
              <Card><CardContent className="py-12 text-center text-muted-foreground">
                <Ticket className="w-10 h-10 mx-auto mb-2 opacity-20" />
                <p className="font-heading">No tickets found</p>
              </CardContent></Card>
            ) : (
              filteredTickets.map((ticket, i) => {
                const StatusIcon = STATUS_ICONS[ticket.status] || Clock;
                const isOverdue = ticket.due_date && ticket.status !== "closed" && ticket.status !== "resolved" && new Date(ticket.due_date) < new Date();
                return (
                  <motion.div key={ticket.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: i * 0.03 }}>
                    <Card className={`cursor-pointer hover:shadow-card transition-all ${selectedTicket?.id === ticket.id ? "border-primary ring-1 ring-primary/30" : ""} ${isOverdue ? "border-destructive/30" : ""}`}
                      onClick={() => openTicket(ticket)}>
                      <CardContent className="p-4">
                        <div className="flex items-start gap-3">
                          <StatusIcon className={`w-5 h-5 flex-shrink-0 mt-0.5 ${ticket.status === "open" ? "text-primary" : ticket.status === "in_progress" ? "text-gold" : "text-accent"}`} />
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 flex-wrap">
                              <span className="text-sm font-heading font-semibold text-foreground">{ticket.title}</span>
                              <Badge variant="secondary" className={PRIORITY_COLORS[ticket.priority]}>{ticket.priority}</Badge>
                              {isOverdue && <Badge variant="destructive" className="text-[10px]">Overdue</Badge>}
                            </div>
                            <div className="text-xs text-muted-foreground mt-1">
                              #{ticket.ticket_number} · {ticket.category} · {profiles[ticket.created_by]?.full_name || "Unknown"} · {new Date(ticket.created_at).toLocaleDateString()}
                              {ticket.due_date && <span className="ml-1">· Due {format(new Date(ticket.due_date), "MMM d")}</span>}
                            </div>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  </motion.div>
                );
              })
            )}
          </div>

          {/* Detail */}
          <div className="lg:col-span-2">
            {selectedTicket ? (
              <Card className="sticky top-20">
                <CardHeader className="pb-3">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-base font-heading">Ticket #{selectedTicket.ticket_number}</CardTitle>
                    <button onClick={() => setSelectedTicket(null)} className="text-muted-foreground hover:text-foreground"><X className="w-4 h-4" /></button>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <h3 className="font-heading font-semibold text-foreground">{selectedTicket.title}</h3>
                    <p className="text-sm text-muted-foreground mt-1">{selectedTicket.description}</p>
                  </div>
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <div><span className="text-muted-foreground">Status:</span> <Badge variant="secondary" className="ml-1">{selectedTicket.status.replace("_", " ")}</Badge></div>
                    <div><span className="text-muted-foreground">Priority:</span> <Badge className={`ml-1 ${PRIORITY_COLORS[selectedTicket.priority]}`}>{selectedTicket.priority}</Badge></div>
                    <div><span className="text-muted-foreground">Category:</span> <span className="text-foreground ml-1">{selectedTicket.category}</span></div>
                    <div><span className="text-muted-foreground">By:</span> <span className="text-foreground ml-1">{profiles[selectedTicket.created_by]?.full_name}</span></div>
                    {selectedTicket.due_date && (
                      <div className="col-span-2"><span className="text-muted-foreground">Due:</span> <span className="text-foreground ml-1">{format(new Date(selectedTicket.due_date), "MMM d, yyyy")}</span></div>
                    )}
                    {selectedTicket.assigned_to && <div className="col-span-2"><span className="text-muted-foreground">Assigned:</span> <span className="text-foreground ml-1">{profiles[selectedTicket.assigned_to]?.full_name}</span></div>}
                  </div>

                  {/* Actions */}
                  <div className="flex gap-2 flex-wrap">
                    {canAssign(selectedTicket) && (
                      <Button size="sm" variant="outline" onClick={() => setShowAssign(!showAssign)} className="gap-1">
                        <UserPlus className="w-3 h-3" />Assign
                      </Button>
                    )}
                    {selectedTicket.status === "open" && <Button size="sm" variant="outline" onClick={() => updateTicketStatus(selectedTicket.id, "in_progress")}>Start Work</Button>}
                    {selectedTicket.status === "in_progress" && <Button size="sm" variant="outline" onClick={() => updateTicketStatus(selectedTicket.id, "resolved")}>Resolve</Button>}
                    {selectedTicket.status === "resolved" && <Button size="sm" variant="outline" onClick={() => updateTicketStatus(selectedTicket.id, "closed")}>Close</Button>}
                  </div>

                  {/* Assign dropdown */}
                  <AnimatePresence>
                    {showAssign && (
                      <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: "auto" }} exit={{ opacity: 0, height: 0 }}>
                        <div className="border border-border rounded-lg p-2 space-y-1 max-h-40 overflow-y-auto">
                          <p className="text-[10px] text-muted-foreground font-heading uppercase tracking-wide px-1">Assign to:</p>
                          {profilesList.map((p) => (
                            <button key={p.user_id} onClick={() => assignTicket(selectedTicket.id, p.user_id)}
                              className={`w-full text-left px-2 py-1.5 rounded text-xs hover:bg-muted transition-colors flex items-center gap-2 ${selectedTicket.assigned_to === p.user_id ? "bg-primary/10 text-primary" : "text-foreground"}`}>
                              <div className="w-5 h-5 rounded-full gradient-brand flex items-center justify-center text-[8px] text-primary-foreground font-bold">{p.full_name?.charAt(0)}</div>
                              <span>{p.full_name}</span>
                              {p.position && <span className="text-muted-foreground ml-auto">{p.position}</span>}
                            </button>
                          ))}
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>

                  {/* Comments */}
                  <div className="border-t border-border pt-3">
                    <h4 className="text-sm font-heading font-semibold flex items-center gap-1.5 mb-3">
                      <MessageCircle className="w-4 h-4" />Comments
                    </h4>
                    <div className="space-y-2 max-h-48 overflow-y-auto">
                      {comments.map((c) => (
                        <div key={c.id} className="p-2 bg-muted/50 rounded-lg">
                          <div className="flex items-center gap-1.5">
                            <div className="text-xs font-semibold text-foreground">{profiles[c.author_id]?.full_name}</div>
                            <span className="text-[10px] text-muted-foreground">{format(new Date(c.created_at), "MMM d, h:mm a")}</span>
                          </div>
                          <div className="text-xs text-muted-foreground mt-0.5">{c.content}</div>
                        </div>
                      ))}
                      {comments.length === 0 && <p className="text-xs text-muted-foreground">No comments yet</p>}
                    </div>
                    <div className="flex gap-2 mt-2">
                      <Input placeholder="Add comment..." value={newComment} onChange={(e) => setNewComment(e.target.value)} className="text-sm"
                        onKeyDown={(e) => e.key === "Enter" && addComment()} />
                      <Button size="sm" onClick={addComment} className="gradient-brand text-primary-foreground">Send</Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ) : (
              <Card>
                <CardContent className="py-12 text-center text-muted-foreground">
                  <Ticket className="w-8 h-8 mx-auto mb-2 opacity-20" />
                  <p className="text-sm font-heading">Select a ticket to view details</p>
                </CardContent>
              </Card>
            )}
          </div>
        </div>
      </div>
    </StaffLayout>
  );
}
