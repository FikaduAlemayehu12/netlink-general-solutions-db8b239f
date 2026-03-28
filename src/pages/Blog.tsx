import { motion } from "framer-motion";
import { Calendar, User, ArrowRight, Tag } from "lucide-react";
import { Link } from "react-router-dom";

const posts = [
  {
    title: "The Future of Enterprise Networking in Ethiopia",
    excerpt: "As Ethiopia rapidly digitizes, enterprise networking is becoming the backbone of modern business operations. SDN and WLAN solutions are leading the charge.",
    author: "Mr. Feyisa Bekele",
    date: "February 2025",
    category: "Networking",
    readTime: "5 min read",
  },
  {
    title: "Cybersecurity Threats Facing African Businesses in 2025",
    excerpt: "From ransomware to phishing attacks, African enterprises must fortify their defenses. Our SOC team shares the top threats and how to mitigate them.",
    author: "Netlink Security Team",
    date: "January 2025",
    category: "Cybersecurity",
    readTime: "7 min read",
  },
  {
    title: "Solar-Powered Data Centers: A Sustainable Future for IT",
    excerpt: "With Ethiopia's abundant solar resources, data centers powered by renewable energy represent both an economic and environmental opportunity.",
    author: "Mr. Endale",
    date: "December 2024",
    category: "Infrastructure",
    readTime: "4 min read",
  },
  {
    title: "ERP Implementation: Lessons from the Ethiopian Market",
    excerpt: "Implementing ERP systems in Ethiopia comes with unique challenges. We share key insights from our deployments and what made them successful.",
    author: "Mr. Ysak Alemayehu",
    date: "November 2024",
    category: "Business Solutions",
    readTime: "6 min read",
  },
  {
    title: "IoT and Smart Buildings: Transforming Ethiopian Workplaces",
    excerpt: "From automated lighting to security systems, IoT is reshaping how Ethiopian companies manage their facilities.",
    author: "Ms. Hana Alemu",
    date: "October 2024",
    category: "Smart Infrastructure",
    readTime: "5 min read",
  },
  {
    title: "Netlink General Solutions: Our Journey in 2024",
    excerpt: "A year of growth, partnerships, and delivered projects — we reflect on what we've achieved and where we're headed as a leading Ethiopian IT company.",
    author: "Mr. Fikadu Alemayehu",
    date: "October 2024",
    category: "Company News",
    readTime: "3 min read",
  },
];

const catColors: Record<string, string> = {
  "Networking": "bg-cyan-brand/10 text-cyan-brand",
  "Cybersecurity": "bg-red-100 text-red-600",
  "Infrastructure": "bg-gold/10 text-gold",
  "Business Solutions": "bg-purple-100 text-purple-600",
  "Smart Infrastructure": "bg-green-100 text-green-600",
  "Company News": "bg-secondary text-secondary-foreground",
};

export default function Blog() {
  return (
    <main className="min-h-screen pt-16">
      {/* Hero */}
      <section className="gradient-hero py-24 relative overflow-hidden">
        <div className="absolute inset-0 network-pattern opacity-20" />
        <div className="relative container mx-auto px-4 text-center">
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
            <div className="inline-block px-3 py-1 bg-cyan-brand/10 border border-cyan-brand/30 text-cyan-brand text-xs tracking-widest uppercase rounded-full mb-4">
              Insights & News
            </div>
            <h1 className="font-heading font-bold text-5xl md:text-6xl text-primary-foreground mb-4">Blog & News</h1>
            <p className="text-primary-foreground/70 max-w-xl mx-auto">
              Industry insights, company updates, and thought leadership from our experts.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Posts */}
      <section className="py-20 bg-background">
        <div className="container mx-auto px-4">
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {posts.map(({ title, excerpt, author, date, category, readTime }, i) => (
              <motion.article
                key={title}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.08, duration: 0.5 }}
                className="bg-card rounded-xl border border-border shadow-card hover:border-cyan-brand/30 hover:shadow-glow transition-all group flex flex-col"
              >
                {/* Category bar */}
                <div className="h-1.5 rounded-t-xl bg-gradient-to-r from-cyan-brand to-transparent" />
                <div className="p-6 flex flex-col flex-1">
                  <div className="flex items-center gap-2 mb-3">
                    <span className={`inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded-full font-medium ${catColors[category] ?? "bg-secondary text-secondary-foreground"}`}>
                      <Tag className="w-2.5 h-2.5" /> {category}
                    </span>
                    <span className="text-xs text-muted-foreground">{readTime}</span>
                  </div>
                  <h2 className="font-heading font-bold text-lg mb-3 group-hover:text-cyan-brand transition-colors leading-snug">
                    {title}
                  </h2>
                  <p className="text-muted-foreground text-sm leading-relaxed flex-1 mb-4">{excerpt}</p>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2 text-xs text-muted-foreground">
                      <User className="w-3 h-3" /> {author}
                      <Calendar className="w-3 h-3 ml-1" /> {date}
                    </div>
                    <Link to="#" className="inline-flex items-center gap-1 text-xs font-medium text-cyan-brand group-hover:gap-2 transition-all">
                      Read <ArrowRight className="w-3 h-3" />
                    </Link>
                  </div>
                </div>
              </motion.article>
            ))}
          </div>
        </div>
      </section>
    </main>
  );
}
