import { motion } from "framer-motion";
import { Briefcase, Users, Heart, Zap } from "lucide-react";
import { useState } from "react";

const jobs = [
  {
    title: "Network Engineer",
    type: "Full-time",
    location: "Addis Ababa",
    dept: "Engineering",
    desc: "Design, implement, and manage enterprise network solutions for our clients.",
  },
  {
    title: "Cybersecurity Analyst",
    type: "Full-time",
    location: "Addis Ababa",
    dept: "Security",
    desc: "Monitor, detect, and respond to cybersecurity incidents across client environments.",
  },
  {
    title: "Data Center Engineer",
    type: "Full-time",
    location: "Addis Ababa",
    dept: "Infrastructure",
    desc: "Maintain and optimize data center facilities and power systems.",
  },
  {
    title: "ERP Consultant",
    type: "Full-time",
    location: "Addis Ababa",
    dept: "Business Solutions",
    desc: "Implement and customize ERP solutions for enterprise clients.",
  },
  {
    title: "Software Engineer",
    type: "Full-time",
    location: "Addis Ababa",
    dept: "Software",
    desc: "Build innovative software products and digital office solutions.",
  },
];

const benefits = [
  { icon: Users, label: "Team Culture", desc: "Collaborative, diverse team of certified professionals" },
  { icon: Zap, label: "Growth", desc: "International certification support and career advancement" },
  { icon: Heart, label: "Benefits", desc: "Competitive salary, health coverage, and leave policies" },
  { icon: Briefcase, label: "Impact", desc: "Shape Ethiopia's technological future every day" },
];

export default function Careers() {
  const [form, setForm] = useState({ name: "", email: "", position: "", message: "" });
  const [submitted, setSubmitted] = useState(false);

  const handle = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
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
            {benefits.map(({ icon: Icon, label, desc }, i) => (
              <motion.div
                key={label}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                className="p-6 bg-card rounded-xl border border-border shadow-card text-center"
              >
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

      {/* Jobs */}
      <section className="py-16 bg-secondary/40">
        <div className="container mx-auto px-4 max-w-4xl">
          <h2 className="font-heading font-bold text-3xl mb-8">Open Positions</h2>
          <div className="flex flex-col gap-4">
            {jobs.map(({ title, type, location, dept, desc }, i) => (
              <motion.div
                key={title}
                initial={{ opacity: 0, x: -20 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.08 }}
                className="p-5 bg-card rounded-xl border border-border shadow-card hover:border-cyan-brand/30 transition-all flex flex-col sm:flex-row sm:items-center gap-4"
              >
                <div className="flex-1">
                  <div className="flex flex-wrap gap-2 mb-2">
                    <span className="text-xs px-2 py-0.5 bg-cyan-brand/10 text-cyan-brand rounded-full">{dept}</span>
                    <span className="text-xs px-2 py-0.5 bg-secondary text-secondary-foreground rounded-full">{type}</span>
                    <span className="text-xs px-2 py-0.5 bg-secondary text-secondary-foreground rounded-full">{location}</span>
                  </div>
                  <div className="font-heading font-semibold text-base">{title}</div>
                  <div className="text-sm text-muted-foreground mt-1">{desc}</div>
                </div>
                <button className="shrink-0 px-4 py-2 gradient-brand text-primary-foreground text-sm font-heading font-semibold rounded-lg hover:opacity-90 transition-opacity">
                  Apply Now
                </button>
              </motion.div>
            ))}
          </div>
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
          ) : (
            <form onSubmit={submit} className="space-y-4">
              <div className="grid sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-1.5">Full Name *</label>
                  <input name="name" required value={form.name} onChange={handle} placeholder="Your name"
                    className="w-full px-4 py-2.5 rounded-lg border border-border bg-card text-sm outline-none focus:ring-2 focus:ring-ring" />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1.5">Email *</label>
                  <input name="email" type="email" required value={form.email} onChange={handle} placeholder="you@email.com"
                    className="w-full px-4 py-2.5 rounded-lg border border-border bg-card text-sm outline-none focus:ring-2 focus:ring-ring" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1.5">Position of Interest</label>
                <select name="position" value={form.position} onChange={handle}
                  className="w-full px-4 py-2.5 rounded-lg border border-border bg-card text-sm outline-none focus:ring-2 focus:ring-ring">
                  <option value="">Select a position...</option>
                  {jobs.map((j) => <option key={j.title}>{j.title}</option>)}
                  <option>Other</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1.5">Cover Letter / Message *</label>
                <textarea name="message" required value={form.message} onChange={handle} rows={5} placeholder="Tell us about yourself..."
                  className="w-full px-4 py-2.5 rounded-lg border border-border bg-card text-sm outline-none focus:ring-2 focus:ring-ring resize-none" />
              </div>
              <button type="submit" className="w-full py-3 gradient-brand text-primary-foreground font-heading font-semibold rounded-lg hover:opacity-90 transition-opacity shadow-glow">
                Submit Application
              </button>
            </form>
          )}
        </div>
      </section>
    </main>
  );
}
