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
    PostgrestVersion: "14.15"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      blocks: {
        Row: {
          blocked_id: string
          blocker_id: string
          created_at: string
        }
        Insert: {
          blocked_id: string
          blocker_id: string
          created_at?: string
        }
        Update: {
          blocked_id?: string
          blocker_id?: string
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "blocks_blocked_id_fkey"
            columns: ["blocked_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "blocks_blocker_id_fkey"
            columns: ["blocker_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      churches: {
        Row: {
          created_at: string
          denomination: string | null
          id: string
          name: string
          region: string | null
          use_count: number
        }
        Insert: {
          created_at?: string
          denomination?: string | null
          id?: string
          name: string
          region?: string | null
          use_count?: number
        }
        Update: {
          created_at?: string
          denomination?: string | null
          id?: string
          name?: string
          region?: string | null
          use_count?: number
        }
        Relationships: []
      }
      comments: {
        Row: {
          author_id: string
          body: string
          community_id: string
          created_at: string
          id: string
          post_id: string
        }
        Insert: {
          author_id: string
          body: string
          community_id: string
          created_at?: string
          id?: string
          post_id: string
        }
        Update: {
          author_id?: string
          body?: string
          community_id?: string
          created_at?: string
          id?: string
          post_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "comments_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_community_id_fkey"
            columns: ["community_id"]
            isOneToOne: false
            referencedRelation: "communities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "comments_post_id_community_id_fkey"
            columns: ["post_id", "community_id"]
            isOneToOne: false
            referencedRelation: "post_targets"
            referencedColumns: ["post_id", "community_id"]
          },
          {
            foreignKeyName: "comments_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
        ]
      }
      communities: {
        Row: {
          cover_path: string | null
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          invite_policy: Database["public"]["Enums"]["invite_policy"]
          kind: Database["public"]["Enums"]["community_kind"]
          name: string
          type: Database["public"]["Enums"]["community_type"]
          updated_at: string
        }
        Insert: {
          cover_path?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          invite_policy?: Database["public"]["Enums"]["invite_policy"]
          kind?: Database["public"]["Enums"]["community_kind"]
          name: string
          type?: Database["public"]["Enums"]["community_type"]
          updated_at?: string
        }
        Update: {
          cover_path?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          invite_policy?: Database["public"]["Enums"]["invite_policy"]
          kind?: Database["public"]["Enums"]["community_kind"]
          name?: string
          type?: Database["public"]["Enums"]["community_type"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "communities_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      community_invites: {
        Row: {
          code: string
          community_id: string
          created_at: string
          created_by: string
          expires_at: string | null
          id: string
          max_uses: number | null
          revoked_at: string | null
          used_count: number
        }
        Insert: {
          code: string
          community_id: string
          created_at?: string
          created_by: string
          expires_at?: string | null
          id?: string
          max_uses?: number | null
          revoked_at?: string | null
          used_count?: number
        }
        Update: {
          code?: string
          community_id?: string
          created_at?: string
          created_by?: string
          expires_at?: string | null
          id?: string
          max_uses?: number | null
          revoked_at?: string | null
          used_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "community_invites_community_id_fkey"
            columns: ["community_id"]
            isOneToOne: false
            referencedRelation: "communities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "community_invites_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      community_members: {
        Row: {
          community_id: string
          invited_by: string | null
          joined_at: string
          role: Database["public"]["Enums"]["member_role"]
          user_id: string
        }
        Insert: {
          community_id: string
          invited_by?: string | null
          joined_at?: string
          role?: Database["public"]["Enums"]["member_role"]
          user_id: string
        }
        Update: {
          community_id?: string
          invited_by?: string | null
          joined_at?: string
          role?: Database["public"]["Enums"]["member_role"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "community_members_community_id_fkey"
            columns: ["community_id"]
            isOneToOne: false
            referencedRelation: "communities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "community_members_invited_by_fkey"
            columns: ["invited_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "community_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      missionary_info: {
        Row: {
          agency: string | null
          created_at: string
          field_country: string | null
          field_label: string | null
          is_church_hidden: boolean
          is_location_hidden: boolean
          ministry_desc: string | null
          missionary_type: Database["public"]["Enums"]["missionary_type"]
          profile_id: string
          sending_church: string | null
          updated_at: string
        }
        Insert: {
          agency?: string | null
          created_at?: string
          field_country?: string | null
          field_label?: string | null
          is_church_hidden?: boolean
          is_location_hidden?: boolean
          ministry_desc?: string | null
          missionary_type: Database["public"]["Enums"]["missionary_type"]
          profile_id: string
          sending_church?: string | null
          updated_at?: string
        }
        Update: {
          agency?: string | null
          created_at?: string
          field_country?: string | null
          field_label?: string | null
          is_church_hidden?: boolean
          is_location_hidden?: boolean
          ministry_desc?: string | null
          missionary_type?: Database["public"]["Enums"]["missionary_type"]
          profile_id?: string
          sending_church?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "missionary_info_profile_id_fkey"
            columns: ["profile_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          created_at: string
          id: string
          payload: Json
          read_at: string | null
          type: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          payload?: Json
          read_at?: string | null
          type: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          payload?: Json
          read_at?: string | null
          type?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      post_media: {
        Row: {
          id: string
          post_id: string
          sort_order: number
          storage_path: string
        }
        Insert: {
          id?: string
          post_id: string
          sort_order?: number
          storage_path: string
        }
        Update: {
          id?: string
          post_id?: string
          sort_order?: number
          storage_path?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_media_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
        ]
      }
      post_targets: {
        Row: {
          community_id: string
          created_at: string
          post_id: string
        }
        Insert: {
          community_id: string
          created_at?: string
          post_id: string
        }
        Update: {
          community_id?: string
          created_at?: string
          post_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "post_targets_community_id_fkey"
            columns: ["community_id"]
            isOneToOne: false
            referencedRelation: "communities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "post_targets_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
        ]
      }
      posts: {
        Row: {
          author_id: string
          body: string
          created_at: string
          id: string
          is_answered: boolean
          type: Database["public"]["Enums"]["post_type"]
          updated_at: string
        }
        Insert: {
          author_id: string
          body: string
          created_at?: string
          id?: string
          is_answered?: boolean
          type: Database["public"]["Enums"]["post_type"]
          updated_at?: string
        }
        Update: {
          author_id?: string
          body?: string
          created_at?: string
          id?: string
          is_answered?: boolean
          type?: Database["public"]["Enums"]["post_type"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "posts_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_path: string | null
          bio: string | null
          created_at: string
          display_name: string
          home_church: string
          home_region: string | null
          id: string
          is_admin: boolean
          is_missionary: boolean
          updated_at: string
          verified_at: string | null
          verified_by: string | null
        }
        Insert: {
          avatar_path?: string | null
          bio?: string | null
          created_at?: string
          display_name: string
          home_church: string
          home_region?: string | null
          id: string
          is_admin?: boolean
          is_missionary?: boolean
          updated_at?: string
          verified_at?: string | null
          verified_by?: string | null
        }
        Update: {
          avatar_path?: string | null
          bio?: string | null
          created_at?: string
          display_name?: string
          home_church?: string
          home_region?: string | null
          id?: string
          is_admin?: boolean
          is_missionary?: boolean
          updated_at?: string
          verified_at?: string | null
          verified_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "profiles_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      reactions: {
        Row: {
          community_id: string
          created_at: string
          kind: Database["public"]["Enums"]["reaction_kind"]
          post_id: string
          user_id: string
        }
        Insert: {
          community_id: string
          created_at?: string
          kind?: Database["public"]["Enums"]["reaction_kind"]
          post_id: string
          user_id: string
        }
        Update: {
          community_id?: string
          created_at?: string
          kind?: Database["public"]["Enums"]["reaction_kind"]
          post_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "reactions_community_id_fkey"
            columns: ["community_id"]
            isOneToOne: false
            referencedRelation: "communities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reactions_post_id_community_id_fkey"
            columns: ["post_id", "community_id"]
            isOneToOne: false
            referencedRelation: "post_targets"
            referencedColumns: ["post_id", "community_id"]
          },
          {
            foreignKeyName: "reactions_post_id_fkey"
            columns: ["post_id"]
            isOneToOne: false
            referencedRelation: "posts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reactions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      reports: {
        Row: {
          community_id: string | null
          created_at: string
          id: string
          reason: string
          reporter_id: string
          status: Database["public"]["Enums"]["report_status"]
          target_id: string
          target_type: Database["public"]["Enums"]["report_target"]
        }
        Insert: {
          community_id?: string | null
          created_at?: string
          id?: string
          reason: string
          reporter_id: string
          status?: Database["public"]["Enums"]["report_status"]
          target_id: string
          target_type: Database["public"]["Enums"]["report_target"]
        }
        Update: {
          community_id?: string | null
          created_at?: string
          id?: string
          reason?: string
          reporter_id?: string
          status?: Database["public"]["Enums"]["report_status"]
          target_id?: string
          target_type?: Database["public"]["Enums"]["report_target"]
        }
        Relationships: [
          {
            foreignKeyName: "reports_community_id_fkey"
            columns: ["community_id"]
            isOneToOne: false
            referencedRelation: "communities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reports_reporter_id_fkey"
            columns: ["reporter_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      stay_addresses: {
        Row: {
          address_detail: string | null
          address_line: string
          contact: string | null
          stay_id: string
          updated_at: string
        }
        Insert: {
          address_detail?: string | null
          address_line: string
          contact?: string | null
          stay_id: string
          updated_at?: string
        }
        Update: {
          address_detail?: string | null
          address_line?: string
          contact?: string | null
          stay_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "stay_addresses_stay_id_fkey"
            columns: ["stay_id"]
            isOneToOne: true
            referencedRelation: "stays"
            referencedColumns: ["id"]
          },
        ]
      }
      stay_audience: {
        Row: {
          community_id: string | null
          id: string
          missionary_id: string | null
          stay_id: string
        }
        Insert: {
          community_id?: string | null
          id?: string
          missionary_id?: string | null
          stay_id: string
        }
        Update: {
          community_id?: string | null
          id?: string
          missionary_id?: string | null
          stay_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "stay_audience_community_id_fkey"
            columns: ["community_id"]
            isOneToOne: false
            referencedRelation: "communities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "stay_audience_missionary_id_fkey"
            columns: ["missionary_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "stay_audience_stay_id_fkey"
            columns: ["stay_id"]
            isOneToOne: false
            referencedRelation: "stays"
            referencedColumns: ["id"]
          },
        ]
      }
      stay_media: {
        Row: {
          id: string
          sort_order: number
          stay_id: string
          storage_path: string
        }
        Insert: {
          id?: string
          sort_order?: number
          stay_id: string
          storage_path: string
        }
        Update: {
          id?: string
          sort_order?: number
          stay_id?: string
          storage_path?: string
        }
        Relationships: [
          {
            foreignKeyName: "stay_media_stay_id_fkey"
            columns: ["stay_id"]
            isOneToOne: false
            referencedRelation: "stays"
            referencedColumns: ["id"]
          },
        ]
      }
      stay_requests: {
        Row: {
          created_at: string
          date_from: string
          date_to: string
          guest_id: string
          headcount: number
          id: string
          message: string | null
          status: Database["public"]["Enums"]["request_status"]
          stay_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          date_from: string
          date_to: string
          guest_id: string
          headcount?: number
          id?: string
          message?: string | null
          status?: Database["public"]["Enums"]["request_status"]
          stay_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          date_from?: string
          date_to?: string
          guest_id?: string
          headcount?: number
          id?: string
          message?: string | null
          status?: Database["public"]["Enums"]["request_status"]
          stay_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "stay_requests_guest_id_fkey"
            columns: ["guest_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "stay_requests_stay_id_fkey"
            columns: ["stay_id"]
            isOneToOne: false
            referencedRelation: "stays"
            referencedColumns: ["id"]
          },
        ]
      }
      stays: {
        Row: {
          available_from: string | null
          available_to: string | null
          capacity: number
          cost_amount: number | null
          cost_type: Database["public"]["Enums"]["cost_type"]
          created_at: string
          description: string | null
          host_id: string
          house_rules: string | null
          id: string
          region_label: string
          status: Database["public"]["Enums"]["stay_status"]
          title: string
          updated_at: string
          visibility: Database["public"]["Enums"]["stay_visibility"]
        }
        Insert: {
          available_from?: string | null
          available_to?: string | null
          capacity?: number
          cost_amount?: number | null
          cost_type?: Database["public"]["Enums"]["cost_type"]
          created_at?: string
          description?: string | null
          host_id: string
          house_rules?: string | null
          id?: string
          region_label: string
          status?: Database["public"]["Enums"]["stay_status"]
          title: string
          updated_at?: string
          visibility?: Database["public"]["Enums"]["stay_visibility"]
        }
        Update: {
          available_from?: string | null
          available_to?: string | null
          capacity?: number
          cost_amount?: number | null
          cost_type?: Database["public"]["Enums"]["cost_type"]
          created_at?: string
          description?: string | null
          host_id?: string
          house_rules?: string | null
          id?: string
          region_label?: string
          status?: Database["public"]["Enums"]["stay_status"]
          title?: string
          updated_at?: string
          visibility?: Database["public"]["Enums"]["stay_visibility"]
        }
        Relationships: [
          {
            foreignKeyName: "stays_host_id_fkey"
            columns: ["host_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      support_accounts: {
        Row: {
          account_no: string
          bank: string
          created_at: string
          holder: string
          id: string
          missionary_id: string
          note: string | null
          qr_path: string | null
          updated_at: string
        }
        Insert: {
          account_no: string
          bank: string
          created_at?: string
          holder: string
          id?: string
          missionary_id: string
          note?: string | null
          qr_path?: string | null
          updated_at?: string
        }
        Update: {
          account_no?: string
          bank?: string
          created_at?: string
          holder?: string
          id?: string
          missionary_id?: string
          note?: string | null
          qr_path?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "support_accounts_missionary_id_fkey"
            columns: ["missionary_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      support_logs: {
        Row: {
          created_at: string
          id: string
          missionary_id: string
          supporter_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          missionary_id: string
          supporter_id: string
        }
        Update: {
          created_at?: string
          id?: string
          missionary_id?: string
          supporter_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "support_logs_missionary_id_fkey"
            columns: ["missionary_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "support_logs_supporter_id_fkey"
            columns: ["supporter_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      can_invite_to: { Args: { cid: string }; Returns: boolean }
      can_view_post: { Args: { pid: string }; Returns: boolean }
      can_view_stay: { Args: { sid: string }; Returns: boolean }
      create_community: {
        Args: {
          p_description?: string
          p_invite_policy?: Database["public"]["Enums"]["invite_policy"]
          p_kind?: Database["public"]["Enums"]["community_kind"]
          p_name: string
        }
        Returns: {
          cover_path: string | null
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          invite_policy: Database["public"]["Enums"]["invite_policy"]
          kind: Database["public"]["Enums"]["community_kind"]
          name: string
          type: Database["public"]["Enums"]["community_type"]
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "communities"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      has_accepted_stay_request: { Args: { sid: string }; Returns: boolean }
      is_admin: { Args: never; Returns: boolean }
      is_community_member: { Args: { cid: string }; Returns: boolean }
      is_community_owner: { Args: { cid: string }; Returns: boolean }
      is_verified_missionary: { Args: never; Returns: boolean }
      join_community_by_code: { Args: { p_code: string }; Returns: string }
      owns_storage_path: { Args: { object_name: string }; Returns: boolean }
      preview_invite: {
        Args: { p_code: string }
        Returns: {
          community_id: string
          description: string
          kind: Database["public"]["Enums"]["community_kind"]
          member_count: number
          name: string
        }[]
      }
      record_church: {
        Args: { p_name: string; p_region?: string }
        Returns: string
      }
      stay_visible_to_me: {
        Args: {
          p_host_id: string
          p_status: Database["public"]["Enums"]["stay_status"]
          p_stay_id: string
          p_visibility: Database["public"]["Enums"]["stay_visibility"]
        }
        Returns: boolean
      }
    }
    Enums: {
      community_kind: "church" | "agency" | "prayer" | "etc"
      community_type: "private" | "open"
      cost_type: "free" | "actual_cost" | "paid"
      invite_policy: "owner" | "member"
      member_role: "owner" | "member"
      missionary_type: "sent" | "self_supported" | "other"
      post_type: "prayer" | "testimony" | "share" | "photo"
      reaction_kind: "prayed" | "amen"
      report_status: "open" | "reviewing" | "resolved" | "dismissed"
      report_target: "post" | "comment" | "profile" | "stay" | "community"
      request_status: "pending" | "accepted" | "declined" | "cancelled"
      stay_status: "draft" | "open" | "closed"
      stay_visibility: "members" | "community" | "targeted"
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
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      community_kind: ["church", "agency", "prayer", "etc"],
      community_type: ["private", "open"],
      cost_type: ["free", "actual_cost", "paid"],
      invite_policy: ["owner", "member"],
      member_role: ["owner", "member"],
      missionary_type: ["sent", "self_supported", "other"],
      post_type: ["prayer", "testimony", "share", "photo"],
      reaction_kind: ["prayed", "amen"],
      report_status: ["open", "reviewing", "resolved", "dismissed"],
      report_target: ["post", "comment", "profile", "stay", "community"],
      request_status: ["pending", "accepted", "declined", "cancelled"],
      stay_status: ["draft", "open", "closed"],
      stay_visibility: ["members", "community", "targeted"],
    },
  },
} as const
