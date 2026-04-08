import { motion } from "framer-motion";
import { Briefcase, Users, Heart, Zap, Calendar, DollarSign, Upload, FileText, X, Loader2, LogIn } from "lucide-react";
import { useState, useEffect, useRef } from "react";
import { supabase } from "@/integrations/supabase/client";
import { lovable } from "@/integrations/lovable";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { useToast } from "@/hooks/use-toast";
import { format } from "date-fns";

interface Vacancy {
  id: string;
  title: string;
  department: string | null;
  description: string | null;
  responsibilities: string | null;
  qualifications: string | null;
  skills: string | null;
  experience: string | null;
  education: string | null;
  certifications: string | null;
  employment_type: string;
  salary_range: string | null;
  benefits: string | null;
  location: string | null;
  working_hours: string | null;
  deadline: string | null;
  openings: number;
  reporting_manager: string | null;
  created_at: string;
}

const benefitsList = [
  { icon: Users, label: "Team Culture", desc: "Collaborative, diverse team of certified professionals" },
  { icon: Zap, label: "Growth", desc: "International certification support and career advancement" },
  { icon: Heart, label: "Benefits", desc: "Competitive salary, health coverage, and leave policies" },
  { icon: Briefcase, label: "Impact", desc: "Shape Ethiopia's technological future every day" },
];

export default function Careers() {
  const { toast } = useToast();
  const [vacancies, setVacancies] = useState<Vacancy[]>([]);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [form, setForm] = useState({ name: "", email: "", position: "", message: "" });
  const [cvFile, setCvFile] = useState<File | null>(null);
  const [submitted, setSubmitted] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [signingIn, setSigningIn] = useState(false);
  const [user, setUser] = useState<any>(null);
  const [authLoading, setAuthLoading] = useState(true);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    supabase.from("job_vacancies" as any).select("*").eq("status", "published").eq("vacancy_type", "external").order("created_at", { ascending: false })
      .then(({ data }) => setVacancies((data || []) as any));

    // Check current session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user || null);
      if (session?.user) {
        setForm(f => ({
          ...f,
          name: session.user.user_metadata?.full_name || session.user.user_metadata?.name || f.name,
          email: session.user.email || f.email,
        }));
      }
      setAuthLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user || null);
      if (session?.user) {
        setForm(f => ({
          ...f,
          name: session.user.user_metadata?.full_name || session.user.user_metadata?.name || f.name,
          email: session.user.email || f.email,
        }));
      }
    });
    return () => subscription.unsubscribe();
  }, []);

  const handleGoogleSignIn = async () => {
    setSigningIn(true);
    try {
      await lovable.auth.signInWithOAuth("google", {
        redirect_uri: window.location.href,
      });
    } catch (err: any) {
      toast({ title: "Sign-in failed", description: err.message, variant: "destructive" });
    } finally {
      setSigningIn(false);
    }
  };

  const handle = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
      toast({ title: "File too large", description: "Maximum file size is 10MB", variant: "destructive" });
      return;
    }
    const allowed = [".pdf", ".doc", ".docx"];
    const ext = file.name.toLowerCase().slice(file.name.lastIndexOf("."));
    if (!allowed.includes(ext)) {
      toast({ title: "Invalid file type", description: "Please upload a PDF or Word document", variant: "destructive" });
      return;
    }
    setCvFile(file);
  };

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim() || !form.email.trim() || !form.message.trim()) return;
    setSubmitting(true);

    try {
      let cvUrl: string | null = null;

      if (cvFile) {
        const fileExt = cvFile.name.split(".").pop();
        const fileName = `${Date.now()}-${crypto.randomUUID()}.${fileExt}`;
        const { error: uploadError } = await supabase.storage
          .from("job-applications")
          .upload(fileName, cvFile);
        if (uploadError) {
          toast({ title: "CV upload failed", description: uploadError.message, variant: "destructive" });
          setSubmitting(false);
          return;
        }
        const { data: urlData } = supabase.storage.from("job-applications").getPublicUrl(fileName);
        cvUrl = urlData.publicUrl;
      }

      const matchingVacancy = vacancies.find(v => v.title === form.position);

      const { error } = await supabase.functions.invoke("handle-job-application", {
        body: {
          applicant_name: form.name.trim(),
          applicant_email: form.email.trim(),
          position: form.position || null,
          cover_message: form.message.trim(),
          cv_url: cvUrl,
          vacancy_id: matchingVacancy?.id || null,
        },
      });

      if (error) throw error;
      setSubmitted(true);
    } catch (err: any) {
      toast({ title: "Submission failed", description: err.message || "Please try again later", variant: "destructive" });
    } finally {
      setSubmitting(false);
    }
  };

  const DetailSection = ({ label, value }: { label: string; value: string | null | undefined }) => {
    if (!value) return null;
    return (
      <div>
        <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-1">{label}</p>
        <p className="text-sm text-foreground/80 whitespace-pre-wrap">{value}</p>
      </div>
    );
  };

  return (
    <main className="min-h-screen pt-16">
      {/* Hero */}
      <section className="gradient-hero py-24 relative overflow-hidden">
        <div className="absolute inset-0 network-pattern opacity-20" />
        <div className="relative container mx-auto px-4 text-center">
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
            <div className="inline-block px-3 py-1 bg-cyan-brand/10 border border-cyan-brand/30 text-cyan-brand text-xs tracking-widest uppercase rounded-full mb-4">
              Join Our Team
            </div>
            <h1 className="font-heading font-bold text-5xl md:text-6xl text-primary-foreground mb-4">Careers</h1>
            <p className="text-primary-foreground/70 max-w-xl mx-auto">
              Be part of a mission to transform Ethiopia's technology landscape. We're growing fast.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Benefits */}
      <section className="py-16 bg-background">
        <div className="container mx-auto px-4">
          <h2 className="font-heading font-bold text-3xl text-center mb-10">Why Work with Us?</h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {benefitsList.map(({ icon: Icon, label, desc }, i) => (
              <motion.div key={label} initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.1 }}
                className="p-6 bg-card rounded-xl border border-border shadow-card text-center">
                <div className="w-12 h-12 gradient-brand rounded-xl flex items-center justify-center mx-auto mb-4">
                  <Icon className="w-6 h-6 text-primary-foreground" />
                </div>
                <div className="font-heading font-semibold mb-2">{label}</div>
                <div className="text-sm text-muted-foreground">{desc}</div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Open Positions */}
      <section className="py-16 bg-secondary/40">
        <div className="container mx-auto px-4 max-w-4xl">
          <h2 className="font-heading font-bold text-3xl mb-8">Open Positions</h2>
          {vacancies.length === 0 ? (
            <p className="text-muted-foreground text-center py-8">No open positions at the moment. Check back soon!</p>
          ) : (
            <div className="flex flex-col gap-4">
              {vacancies.map((v, i) => (
                <motion.div key={v.id} initial={{ opacity: 0, x: -20 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.06 }}
                  className="bg-card rounded-xl border border-border shadow-card hover:border-cyan-brand/30 transition-all overflow-hidden">
                  <div className="p-5 flex flex-col sm:flex-row sm:items-center gap-4 cursor-pointer" onClick={() => setExpandedId(expandedId === v.id ? null : v.id)}>
                    <div className="flex-1">
                      <div className="flex flex-wrap gap-2 mb-2">
                        {v.department && <span className="text-xs px-2 py-0.5 bg-cyan-brand/10 text-cyan-brand rounded-full">{v.department}</span>}
                        <Badge variant="outline" className="text-xs">{v.employment_type}</Badge>
                        {v.location && <span className="text-xs px-2 py-0.5 bg-secondary text-secondary-foreground rounded-full">{v.location}</span>}
                      </div>
                      <div className="font-heading font-semibold text-base">{v.title}</div>
                      <div className="flex flex-wrap gap-3 mt-1 text-xs text-muted-foreground">
                        {v.openings > 0 && <span><Users className="w-3 h-3 inline mr-1" />{v.openings} opening{v.openings > 1 ? "s" : ""}</span>}
                        {v.deadline && <span><Calendar className="w-3 h-3 inline mr-1" />Deadline: {format(new Date(v.deadline), "MMM d, yyyy")}</span>}
                        {v.salary_range && <span><DollarSign className="w-3 h-3 inline mr-1" />{v.salary_range}</span>}
                      </div>
                    </div>
                    <button className="shrink-0 px-4 py-2 gradient-brand text-primary-foreground text-sm font-heading font-semibold rounded-lg hover:opacity-90 transition-opacity">
                      {expandedId === v.id ? "Hide Details" : "View Details"}
                    </button>
                  </div>
                  {expandedId === v.id && (
                    <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} exit={{ height: 0, opacity: 0 }}
                      className="border-t border-border px-5 py-4 space-y-3 bg-muted/30">
                      <DetailSection label="Job Description" value={v.description} />
                      <DetailSection label="Responsibilities" value={v.responsibilities} />
                      <DetailSection label="Qualifications" value={v.qualifications} />
                      <DetailSection label="Skills" value={v.skills} />
                      <DetailSection label="Experience" value={v.experience} />
                      <DetailSection label="Education" value={v.education} />
                      <DetailSection label="Certifications" value={v.certifications} />
                      <DetailSection label="Benefits" value={v.benefits} />
                      <DetailSection label="Working Hours" value={v.working_hours} />
                      <DetailSection label="Reporting Manager" value={v.reporting_manager} />
                    </motion.div>
                  )}
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </section>

      {/* Application Form */}
      <section className="py-16 bg-background">
        <div className="container mx-auto px-4 max-w-2xl">
          <h2 className="font-heading font-bold text-3xl mb-2">Submit Your Application</h2>
          <p className="text-muted-foreground text-sm mb-8">Don't see your role? We're always looking for talent.</p>

          {submitted ? (
            <div className="p-8 bg-card rounded-xl border border-cyan-brand/30 text-center shadow-card">
              <div className="font-heading font-bold text-xl mb-2">Application Received!</div>
              <p className="text-muted-foreground text-sm">Thank you for applying. We'll review your application and be in touch soon.</p>
            </div>
          ) : !authLoading && !user ? (
            /* Sign in required */
            <div className="p-8 bg-card rounded-xl border border-border shadow-card text-center space-y-4">
              <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto">
                <LogIn className="w-8 h-8 text-primary" />
              </div>
              <h3 className="font-heading font-semibold text-lg">Sign in to Apply</h3>
              <p className="text-muted-foreground text-sm max-w-md mx-auto">
                Please sign in with your Google account to submit your application. This helps us communicate with you about your application status.
              </p>
              <Button onClick={handleGoogleSignIn} disabled={signingIn} size="lg"
                className="gradient-brand text-primary-foreground gap-2 shadow-glow">
                {signingIn ? <Loader2 className="w-4 h-4 animate-spin" /> : (
                  <svg className="w-4 h-4" viewBox="0 0 24 24">
                    <path fill="currentColor" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"/>
                    <path fill="currentColor" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                    <path fill="currentColor" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                    <path fill="currentColor" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                  </svg>
                )}
                Sign in with Google
              </Button>
            </div>
          ) : (
            <form onSubmit={submit} className="space-y-4">
              {user && (
                <div className="p-3 rounded-lg bg-primary/5 border border-primary/20 flex items-center gap-3 mb-2">
                  <div className="w-8 h-8 rounded-full gradient-brand flex items-center justify-center text-primary-foreground font-heading font-bold text-xs">
                    {(user.user_metadata?.full_name || user.email || "U").charAt(0).toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{user.user_metadata?.full_name || user.email}</p>
                    <p className="text-xs text-muted-foreground truncate">{user.email}</p>
                  </div>
                  <Button variant="ghost" size="sm" onClick={async () => { await supabase.auth.signOut(); setUser(null); }}>
                    Sign out
                  </Button>
                </div>
              )}
              <div className="grid sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-1.5">Full Name *</label>
                  <input name="name" required value={form.name} onChange={handle} placeholder="Your name"
                    className="w-full px-4 py-2.5 rounded-lg border border-border bg-card text-sm outline-none focus:ring-2 focus:ring-ring" />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1.5">Email *</label>
                  <input name="email" type="email" required value={form.email} onChange={handle} placeholder="you@email.com" readOnly={!!user}
                    className="w-full px-4 py-2.5 rounded-lg border border-border bg-card text-sm outline-none focus:ring-2 focus:ring-ring read-only:opacity-70" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1.5">Position of Interest</label>
                <select name="position" value={form.position} onChange={handle}
                  className="w-full px-4 py-2.5 rounded-lg border border-border bg-card text-sm outline-none focus:ring-2 focus:ring-ring">
                  <option value="">Select a position...</option>
                  {vacancies.map(v => <option key={v.id}>{v.title}</option>)}
                  <option>Other</option>
                </select>
              </div>

              {/* CV Upload */}
              <div>
                <label className="block text-sm font-medium mb-1.5">CV / Resume (PDF or Word, max 10MB)</label>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept=".pdf,.doc,.docx"
                  onChange={handleFileChange}
                  className="hidden"
                />
                {cvFile ? (
                  <div className="flex items-center gap-3 px-4 py-3 rounded-lg border border-cyan-brand/30 bg-cyan-brand/5">
                    <FileText className="w-5 h-5 text-cyan-brand flex-shrink-0" />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium truncate">{cvFile.name}</p>
                      <p className="text-xs text-muted-foreground">{(cvFile.size / 1024 / 1024).toFixed(2)} MB</p>
                    </div>
                    <button type="button" onClick={() => { setCvFile(null); if (fileInputRef.current) fileInputRef.current.value = ""; }}
                      className="p-1 rounded hover:bg-destructive/10 text-muted-foreground hover:text-destructive transition-colors">
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                ) : (
                  <button type="button" onClick={() => fileInputRef.current?.click()}
                    className="w-full flex items-center justify-center gap-2 px-4 py-3 rounded-lg border-2 border-dashed border-border hover:border-cyan-brand/40 bg-card text-sm text-muted-foreground hover:text-foreground transition-colors">
                    <Upload className="w-4 h-4" />
                    Click to upload your CV
                  </button>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium mb-1.5">Cover Letter / Message *</label>
                <textarea name="message" required value={form.message} onChange={handle} rows={5} placeholder="Tell us about yourself..."
                  className="w-full px-4 py-2.5 rounded-lg border border-border bg-card text-sm outline-none focus:ring-2 focus:ring-ring resize-none" />
              </div>
              <button type="submit" disabled={submitting}
                className="w-full py-3 gradient-brand text-primary-foreground font-heading font-semibold rounded-lg hover:opacity-90 transition-opacity shadow-glow disabled:opacity-60 flex items-center justify-center gap-2">
                {submitting ? <><Loader2 className="w-4 h-4 animate-spin" /> Submitting...</> : "Submit Application"}
              </button>
            </form>
          )}
        </div>
      </section>
    </main>
  );
}
