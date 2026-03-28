export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.4"
  }
  public: {
    Tables: {
      announcements: {
        Row: {
          author_id: string
          content: string
          created_at: string
          id: string
          pinned: boolean | null
          priority: string
          title: string
          updated_at: string
        }
        Insert: {
          author_id: string
          content: string
          created_at?: string
          id?: string
          pinned?: boolean | null
          priority?: string
          title: string
          updated_at?: string
        }
        Update: {
          author_id?: string
          content?: string
          created_at?: string
          id?: string
          pinned?: boolean | null
          priority?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "announcements_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      attendance: {
        Row: {
          clock_in: string
          clock_out: string | null
          created_at: string
          id: string
          notes: string | null
          overtime_hours: number | null
          user_id: string
          work_hours: number | null
        }
        Insert: {
          clock_in?: string
          clock_out?: string | null
          created_at?: string
          id?: string
          notes?: string | null
          overtime_hours?: number | null
          user_id: string
          work_hours?: number | null
        }
        Update: {
          clock_in?: string
          clock_out?: string | null
          created_at?: string
          id?: string
          notes?: string | null
          overtime_hours?: number | null
          user_id?: string
          work_hours?: number | null
        }
        Relationships: []
      }
      direct_messages: {
        Row: {
          attachment_urls: string[] | null
          content: string
          created_at: string
          id: string
          read: boolean
          receiver_id: string
          sender_id: string
          updated_at: string | null
        }
        Insert: {
          attachment_urls?: string[] | null
          content?: string
          created_at?: string
          id?: string
          read?: boolean
          receiver_id: string
          sender_id: string
          updated_at?: string | null
        }
        Update: {
          attachment_urls?: string[] | null
          content?: string
          created_at?: string
          id?: string
          read?: boolean
          receiver_id?: string
          sender_id?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      dm_reactions: {
        Row: {
          created_at: string
          id: string
          message_id: string
          reaction: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          message_id: string
          reaction: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          message_id?: string
          reaction?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "dm_reactions_message_id_fkey"
            columns: ["message_id"]
            isOneToOne: false
            referencedRelation: "direct_messages"
            referencedColumns: ["id"]
          },
        ]
      }
      leave_requests: {
        Row: {
          approved_at: string | null
          approved_by: string | null
          created_at: string
          end_date: string
          id: string
          leave_type: string
          reason: string | null
          start_date: string
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          end_date: string
          id?: string
          leave_type?: string
          reason?: string | null
          start_date: string
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          end_date?: string
          id?: string
          leave_type?: string
          reason?: string | null
          start_date?: string
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      message_reactions: {
        Row: {
          created_at: string
          id: string
          message_id: string
          reaction: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          message_id: string
          reaction: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          message_id?: string
          reaction?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "message_reactions_message_id_fkey"
            columns: ["message_id"]
            isOneToOne: false
            referencedRelation: "team_messages"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          created_at: string
          id: string
          message: string | null
          read: boolean
          related_id: string | null
          title: string
          type: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          message?: string | null
          read?: boolean
          related_id?: string | null
          title: string
          type: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          message?: string | null
          read?: boolean
          related_id?: string | null
          title?: string
          type?: string
          user_id?: string
        }
        Relationships: []
      }
      performance_scores: {
        Row: {
          assigned_by: string
          created_at: string
          id: string
          notes: string | null
          plan_id: string | null
          points: number
          quarter: string
          staff_id: string
        }
        Insert: {
          assigned_by: string
          created_at?: string
          id?: string
          notes?: string | null
          plan_id?: string | null
          points?: number
          quarter: string
          staff_id: string
        }
        Update: {
          assigned_by?: string
          created_at?: string
          id?: string
          notes?: string | null
          plan_id?: string | null
          points?: number
          quarter?: string
          staff_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "performance_scores_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "performance_scores_plan_id_fkey"
            columns: ["plan_id"]
            isOneToOne: false
            referencedRelation: "plans"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "performance_scores_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      performance_summaries: {
        Row: {
          average_grade: number
          ceo_adjusted_grade: number | null
          ceo_notes: string | null
          created_at: string
          flagged_count: number
          id: string
          period_key: string
          period_type: string
          staff_id: string
          status: string
          total_plans: number
          updated_at: string
        }
        Insert: {
          average_grade?: number
          ceo_adjusted_grade?: number | null
          ceo_notes?: string | null
          created_at?: string
          flagged_count?: number
          id?: string
          period_key: string
          period_type: string
          staff_id: string
          status?: string
          total_plans?: number
          updated_at?: string
        }
        Update: {
          average_grade?: number
          ceo_adjusted_grade?: number | null
          ceo_notes?: string | null
          created_at?: string
          flagged_count?: number
          id?: string
          period_key?: string
          period_type?: string
          staff_id?: string
          status?: string
          total_plans?: number
          updated_at?: string
        }
        Relationships: []
      }
      plan_comments: {
        Row: {
          author_id: string
          content: string
          created_at: string
          id: string
          plan_id: string
        }
        Insert: {
          author_id: string
          content: string
          created_at?: string
          id?: string
          plan_id: string
        }
        Update: {
          author_id?: string
          content?: string
          created_at?: string
          id?: string
          plan_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "plan_comments_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "plan_comments_plan_id_fkey"
            columns: ["plan_id"]
            isOneToOne: false
            referencedRelation: "plans"
            referencedColumns: ["id"]
          },
        ]
      }
      plan_performance_records: {
        Row: {
          achievement_pct: number | null
          actual_value: number
          approved_at: string | null
          approved_by: string | null
          ceo_adjusted_grade: number | null
          ceo_notes: string | null
          created_at: string
          flagged: boolean
          grade: number
          id: string
          period_key: string
          plan_id: string | null
          plan_type: string
          planned_value: number
          staff_id: string
          status: string
          updated_at: string
        }
        Insert: {
          achievement_pct?: number | null
          actual_value?: number
          approved_at?: string | null
          approved_by?: string | null
          ceo_adjusted_grade?: number | null
          ceo_notes?: string | null
          created_at?: string
          flagged?: boolean
          grade?: number
          id?: string
          period_key: string
          plan_id?: string | null
          plan_type?: string
          planned_value?: number
          staff_id: string
          status?: string
          updated_at?: string
        }
        Update: {
          achievement_pct?: number | null
          actual_value?: number
          approved_at?: string | null
          approved_by?: string | null
          ceo_adjusted_grade?: number | null
          ceo_notes?: string | null
          created_at?: string
          flagged?: boolean
          grade?: number
          id?: string
          period_key?: string
          plan_id?: string | null
          plan_type?: string
          planned_value?: number
          staff_id?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "plan_performance_records_plan_id_fkey"
            columns: ["plan_id"]
            isOneToOne: false
            referencedRelation: "plans"
            referencedColumns: ["id"]
          },
        ]
      }
      plan_reactions: {
        Row: {
          id: string
          plan_id: string
          reaction: string
          user_id: string
        }
        Insert: {
          id?: string
          plan_id: string
          reaction: string
          user_id: string
        }
        Update: {
          id?: string
          plan_id?: string
          reaction?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "plan_reactions_plan_id_fkey"
            columns: ["plan_id"]
            isOneToOne: false
            referencedRelation: "plans"
            referencedColumns: ["id"]
          },
        ]
      }
      plans: {
        Row: {
          attachment_urls: string[] | null
          author_id: string
          content: string
          created_at: string
          id: string
          mentioned_user_ids: string[] | null
          plan_type: string
          title: string
          updated_at: string
        }
        Insert: {
          attachment_urls?: string[] | null
          author_id: string
          content: string
          created_at?: string
          id?: string
          mentioned_user_ids?: string[] | null
          plan_type: string
          title: string
          updated_at?: string
        }
        Update: {
          attachment_urls?: string[] | null
          author_id?: string
          content?: string
          created_at?: string
          id?: string
          mentioned_user_ids?: string[] | null
          plan_type?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "plans_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          bio: string | null
          birthday: string | null
          created_at: string
          department: string | null
          email: string
          full_name: string
          id: string
          must_change_password: boolean
          phone: string | null
          position: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          birthday?: string | null
          created_at?: string
          department?: string | null
          email: string
          full_name: string
          id?: string
          must_change_password?: boolean
          phone?: string | null
          position?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          birthday?: string | null
          created_at?: string
          department?: string | null
          email?: string
          full_name?: string
          id?: string
          must_change_password?: boolean
          phone?: string | null
          position?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      project_comments: {
        Row: {
          author_id: string
          content: string
          created_at: string
          group_id: string
          id: string
        }
        Insert: {
          author_id: string
          content: string
          created_at?: string
          group_id: string
          id?: string
        }
        Update: {
          author_id?: string
          content?: string
          created_at?: string
          group_id?: string
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "project_comments_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "project_groups"
            referencedColumns: ["id"]
          },
        ]
      }
      project_groups: {
        Row: {
          budget: number | null
          completed_at: string | null
          created_at: string
          created_by: string
          description: string | null
          end_date: string | null
          final_attachment_urls: string[] | null
          id: string
          manager_id: string | null
          member_ids: string[] | null
          name: string
          start_date: string | null
          status: string | null
          updated_at: string
        }
        Insert: {
          budget?: number | null
          completed_at?: string | null
          created_at?: string
          created_by: string
          description?: string | null
          end_date?: string | null
          final_attachment_urls?: string[] | null
          id?: string
          manager_id?: string | null
          member_ids?: string[] | null
          name: string
          start_date?: string | null
          status?: string | null
          updated_at?: string
        }
        Update: {
          budget?: number | null
          completed_at?: string | null
          created_at?: string
          created_by?: string
          description?: string | null
          end_date?: string | null
          final_attachment_urls?: string[] | null
          id?: string
          manager_id?: string | null
          member_ids?: string[] | null
          name?: string
          start_date?: string | null
          status?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      project_milestones: {
        Row: {
          action_items: string | null
          actual_date: string | null
          created_at: string
          group_id: string
          id: string
          reviewer_id: string | null
          reviewer_notes: string | null
          status: string
          target_date: string
          target_percentage: number
          updated_at: string
        }
        Insert: {
          action_items?: string | null
          actual_date?: string | null
          created_at?: string
          group_id: string
          id?: string
          reviewer_id?: string | null
          reviewer_notes?: string | null
          status?: string
          target_date: string
          target_percentage: number
          updated_at?: string
        }
        Update: {
          action_items?: string | null
          actual_date?: string | null
          created_at?: string
          group_id?: string
          id?: string
          reviewer_id?: string | null
          reviewer_notes?: string | null
          status?: string
          target_date?: string
          target_percentage?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "project_milestones_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "project_groups"
            referencedColumns: ["id"]
          },
        ]
      }
      project_tasks: {
        Row: {
          assigned_to: string | null
          attachments: string[] | null
          created_at: string
          created_by: string
          description: string | null
          due_date: string | null
          group_id: string
          id: string
          priority: string | null
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          attachments?: string[] | null
          created_at?: string
          created_by: string
          description?: string | null
          due_date?: string | null
          group_id: string
          id?: string
          priority?: string | null
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          attachments?: string[] | null
          created_at?: string
          created_by?: string
          description?: string | null
          due_date?: string | null
          group_id?: string
          id?: string
          priority?: string | null
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "project_tasks_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "project_groups"
            referencedColumns: ["id"]
          },
        ]
      }
      project_updates: {
        Row: {
          attachment_urls: string[] | null
          author_id: string
          content: string
          created_at: string
          group_id: string
          id: string
          update_type: string
        }
        Insert: {
          attachment_urls?: string[] | null
          author_id: string
          content: string
          created_at?: string
          group_id: string
          id?: string
          update_type?: string
        }
        Update: {
          attachment_urls?: string[] | null
          author_id?: string
          content?: string
          created_at?: string
          group_id?: string
          id?: string
          update_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "project_updates_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "project_groups"
            referencedColumns: ["id"]
          },
        ]
      }
      quarter_winners: {
        Row: {
          banner_url: string | null
          created_at: string
          id: string
          message: string | null
          posted_by: string
          quarter: string
          winner_id: string
        }
        Insert: {
          banner_url?: string | null
          created_at?: string
          id?: string
          message?: string | null
          posted_by: string
          quarter: string
          winner_id: string
        }
        Update: {
          banner_url?: string | null
          created_at?: string
          id?: string
          message?: string | null
          posted_by?: string
          quarter?: string
          winner_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quarter_winners_posted_by_fkey"
            columns: ["posted_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quarter_winners_winner_id_fkey"
            columns: ["winner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      salary_configs: {
        Row: {
          amount: number
          created_at: string
          created_by: string
          currency: string
          effective_from: string
          effective_to: string | null
          id: string
          notes: string | null
          payment_type: string
          staff_id: string
          updated_at: string
        }
        Insert: {
          amount?: number
          created_at?: string
          created_by: string
          currency?: string
          effective_from: string
          effective_to?: string | null
          id?: string
          notes?: string | null
          payment_type?: string
          staff_id: string
          updated_at?: string
        }
        Update: {
          amount?: number
          created_at?: string
          created_by?: string
          currency?: string
          effective_from?: string
          effective_to?: string | null
          id?: string
          notes?: string | null
          payment_type?: string
          staff_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "salary_configs_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "salary_configs_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      salary_payments: {
        Row: {
          approved_at: string | null
          approved_by: string | null
          base_amount: number
          created_at: string
          created_by: string
          deductions: number
          gross_salary: number
          id: string
          net_salary: number
          notes: string | null
          paid_at: string | null
          payment_type: string
          period_end: string
          period_start: string
          staff_id: string
          status: string
          units: number
          updated_at: string
        }
        Insert: {
          approved_at?: string | null
          approved_by?: string | null
          base_amount?: number
          created_at?: string
          created_by: string
          deductions?: number
          gross_salary?: number
          id?: string
          net_salary?: number
          notes?: string | null
          paid_at?: string | null
          payment_type: string
          period_end: string
          period_start: string
          staff_id: string
          status?: string
          units?: number
          updated_at?: string
        }
        Update: {
          approved_at?: string | null
          approved_by?: string | null
          base_amount?: number
          created_at?: string
          created_by?: string
          deductions?: number
          gross_salary?: number
          id?: string
          net_salary?: number
          notes?: string | null
          paid_at?: string | null
          payment_type?: string
          period_end?: string
          period_start?: string
          staff_id?: string
          status?: string
          units?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "salary_payments_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "salary_payments_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "salary_payments_staff_id_fkey"
            columns: ["staff_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      support_tickets: {
        Row: {
          assigned_to: string | null
          category: string
          closed_at: string | null
          created_at: string
          created_by: string
          description: string
          due_date: string | null
          id: string
          priority: string
          resolved_at: string | null
          status: string
          ticket_number: number
          title: string
          updated_at: string
        }
        Insert: {
          assigned_to?: string | null
          category?: string
          closed_at?: string | null
          created_at?: string
          created_by: string
          description: string
          due_date?: string | null
          id?: string
          priority?: string
          resolved_at?: string | null
          status?: string
          ticket_number?: number
          title: string
          updated_at?: string
        }
        Update: {
          assigned_to?: string | null
          category?: string
          closed_at?: string | null
          created_at?: string
          created_by?: string
          description?: string
          due_date?: string | null
          id?: string
          priority?: string
          resolved_at?: string | null
          status?: string
          ticket_number?: number
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      team_messages: {
        Row: {
          attachment_urls: string[] | null
          content: string
          created_at: string
          group_id: string
          id: string
          sender_id: string
        }
        Insert: {
          attachment_urls?: string[] | null
          content: string
          created_at?: string
          group_id: string
          id?: string
          sender_id: string
        }
        Update: {
          attachment_urls?: string[] | null
          content?: string
          created_at?: string
          group_id?: string
          id?: string
          sender_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "team_messages_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "project_groups"
            referencedColumns: ["id"]
          },
        ]
      }
      ticket_comments: {
        Row: {
          author_id: string
          content: string
          created_at: string
          id: string
          ticket_id: string
        }
        Insert: {
          author_id: string
          content: string
          created_at?: string
          id?: string
          ticket_id: string
        }
        Update: {
          author_id?: string
          content?: string
          created_at?: string
          id?: string
          ticket_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ticket_comments_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "support_tickets"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_ceo: { Args: { _user_id: string }; Returns: boolean }
      is_executive: { Args: { _user_id: string }; Returns: boolean }
    }
    Enums: {
      app_role:
        | "ceo"
        | "cto"
        | "coo"
        | "hr"
        | "sysadmin"
        | "staff"
        | "cio"
        | "finance_manager"
        | "bd_head"
        | "network_engineer"
        | "support_tech"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: [
        "ceo",
        "cto",
        "coo",
        "hr",
        "sysadmin",
        "staff",
        "cio",
        "finance_manager",
        "bd_head",
        "network_engineer",
        "support_tech",
      ],
    },
  },
} as const
