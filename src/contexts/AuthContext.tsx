import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from '@/integrations/supabase/client';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  isAdmin: boolean;
  isLoading: boolean;
  signIn: (email: string, password: string) => Promise<{ error: any }>;
  signUp: (email: string, password: string) => Promise<{ error: any }>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  const checkAdminRole = async (userEmail: string | undefined) => {
    try {
      // Check if user is admin for either organization
      const isOrgAdmin = userEmail === 'info@dkenterprises.co.in' || userEmail === 'info@satguruengravures.com';
      
      if (isOrgAdmin) {
        setIsAdmin(true);
        return;
      }
      
      // Also check database role for other users
      if (userEmail) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('role')
          .eq('email', userEmail)
          .single();
        
        setIsAdmin(profile?.role === 'admin');
      } else {
        setIsAdmin(false);
      }
    } catch (error) {
      console.error('Error checking admin role:', error);
      setIsAdmin(false);
    }
  };

  useEffect(() => {
    // Set up auth state listener
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event, session) => {
        setSession(session);
        setUser(session?.user ?? null);
        
        if (session?.user) {
          // Check admin role based on email
          setTimeout(() => checkAdminRole(session.user.email), 0);
        } else {
          setIsAdmin(false);
        }
        
        setIsLoading(false);
      }
    );

    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      
      if (session?.user) {
        checkAdminRole(session.user.email);
      } else {
        setIsAdmin(false);
      }
      
      setIsLoading(false);
    }).catch((error) => {
      console.error('Error getting session:', error);
      setIsLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const signIn = async (email: string, password: string) => {
    console.log('🔐 Attempting sign in for:', email);
    
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      });
      
      if (error) {
        console.error('❌ Sign in error:', {
          message: error.message,
          status: error.status,
          code: error.code || 'unknown',
          email: email
        });
        
        // Provide more specific error messages
        if (error.message.includes('Invalid login credentials')) {
          console.error('💡 Suggestion: Check if user exists and password is correct for email:', email);
        }
      } else {
        console.log('✅ Sign in successful for:', email, {
          user: data.user?.email,
          session: !!data.session
        });
      }
      
      return { error };
    } catch (err) {
      console.error('🚨 Unexpected sign in error:', err);
      return { error: err as any };
    }
  };

  const signUp = async (email: string, password: string) => {
    console.log('📝 Attempting sign up for:', email);
    const redirectUrl = `${window.location.origin}/`;
    
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          emailRedirectTo: redirectUrl
        }
      });
      
      if (error) {
        console.error('❌ Sign up error:', {
          message: error.message,
          status: error.status,
          code: error.code || 'unknown',
          email: email
        });
      } else {
        console.log('✅ Sign up successful for:', email, {
          user: data.user?.email,
          needsConfirmation: !data.session
        });
      }
      
      return { error };
    } catch (err) {
      console.error('🚨 Unexpected sign up error:', err);
      return { error: err as any };
    }
  };

  const signOut = async () => {
    await supabase.auth.signOut();
  };

  const value = {
    user,
    session,
    isAdmin,
    isLoading,
    signIn,
    signUp,
    signOut
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};