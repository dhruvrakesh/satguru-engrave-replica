import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from './AuthContext';
import { useToast } from '@/hooks/use-toast';

interface Organization {
  id: string;
  name: string;
  code: string;
  description?: string;
  is_active: boolean;
}

interface OrganizationContextType {
  organization: Organization | null;
  isLoading: boolean;
  isSatguru: boolean;
  isDKEGL: boolean;
  getTableName: (baseName: string) => string;
}

const OrganizationContext = createContext<OrganizationContextType | undefined>(undefined);

export const useOrganization = () => {
  const context = useContext(OrganizationContext);
  if (context === undefined) {
    throw new Error('useOrganization must be used within an OrganizationProvider');
  }
  return context;
};

export const OrganizationProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [organization, setOrganization] = useState<Organization | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const { user, isLoading: authIsLoading } = useAuth();
  const { toast } = useToast();

  useEffect(() => {
    const fetchUserOrganization = async () => {
      if (!user) {
        setIsLoading(false);
        setOrganization(null);
        return;
      }

      setIsLoading(true);
      try {
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('organization_id')
          .eq('id', user.id)
          .single();

        if (profileError || !profile || !profile.organization_id) {
          console.error('Error fetching profile or organization_id for user:', user.id, profileError);
          toast({
            title: "Organization Error",
            description: "Could not determine your organization. Please contact support.",
            variant: "destructive"
          });
          setOrganization(null);
          return;
        }
        
        const { data: orgData, error: orgError } = await supabase
          .from('organizations')
          .select('*')
          .eq('id', profile.organization_id)
          .single();

        if (orgError) throw orgError;

        setOrganization(orgData);
        console.log('✅ Organization loaded:', orgData.name);

      } catch (error) {
        console.error('Failed to fetch organization:', error);
        setOrganization(null);
      } finally {
        setIsLoading(false);
      }
    };

    if (!authIsLoading) {
      fetchUserOrganization();
    }
  }, [user, authIsLoading, toast]);
  
  const isSatguru = organization?.code === 'SATGURU';
  const isDKEGL = organization?.code === 'DKEGL';

  const getTableName = (baseName: string): string => {
    if (isSatguru) {
      return `satguru_${baseName}`;
    }
    // DKEGL uses the base table names
    return baseName;
  };

  const value = {
    organization,
    isLoading,
    isSatguru,
    isDKEGL,
    getTableName,
  };

  return (
    <OrganizationContext.Provider value={value}>
      {children}
    </OrganizationContext.Provider>
  );
};