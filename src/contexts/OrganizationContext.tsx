import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from './AuthContext';

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
  switchOrganization: (orgId: string) => void;
  getTableName: (baseName: string) => string;
  isSatguru: boolean;
  isDKEGL: boolean;
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
  const { user } = useAuth();

  const fetchUserOrganization = async () => {
    if (!user) {
      setIsLoading(false);
      return;
    }

    try {
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select(`
          organization_id,
          organizations!inner(*)
        `)
        .eq('id', user.id)
        .single();

      if (profileError) {
        console.error('Error fetching profile:', profileError);
        
        // If profile doesn't exist, try to create one based on email domain
        if (profileError.code === 'PGRST116') { // No rows returned
          console.log('Profile not found, attempting to create one...');
          
          // Determine organization based on email domain
          const isStanguru = user.email?.includes('@satguruengravures.com');
          const isDKEGL = user.email?.includes('@dkenterprises.co.in');
          
          if (isStanguru || isDKEGL) {
            const orgCode = isStanguru ? 'SATGURU' : 'DKEGL';
            
            // Get organization ID
            const { data: org } = await supabase
              .from('organizations')
              .select('id')
              .eq('code', orgCode)
              .single();
            
            if (org) {
              // Create profile
              const { error: createError } = await supabase
                .from('profiles')
                .insert({
                  id: user.id,
                  email: user.email,
                  employee_id: `TEMP_${user.id.substring(0, 8)}`,
                  organization_id: org.id,
                  is_approved: isStanguru || isDKEGL,
                  role: isStanguru || isDKEGL ? 'admin' : 'employee',
                  full_name: user.user_metadata?.full_name || 'User'
                });
              
              if (!createError) {
                // Retry fetching after creation
                setTimeout(() => fetchUserOrganization(), 1000);
                return;
              }
            }
          }
        }
        
        setIsLoading(false);
        return;
      }

      if (profile?.organizations) {
        setOrganization(profile.organizations as Organization);
      }
    } catch (error) {
      console.error('Error fetching user organization:', error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchUserOrganization();
  }, [user]);

  const switchOrganization = async (orgId: string) => {
    if (!user) return;

    try {
      await supabase
        .from('profiles')
        .update({ organization_id: orgId })
        .eq('id', user.id);

      // Fetch updated organization
      await fetchUserOrganization();
    } catch (error) {
      console.error('Error switching organization:', error);
    }
  };

  const getTableName = (baseName: string) => {
    if (!organization) return baseName;
    
    // Map table names based on organization
    if (organization.code === 'SATGURU') {
      switch (baseName) {
        case 'categories':
          return 'satguru_categories';
        case 'item_master':
          return 'satguru_item_master';
        case 'stock':
          return 'satguru_stock';
        case 'grn_log':
          return 'satguru_grn_log';
        case 'issue_log':
          return 'satguru_issue_log';
        case 'daily_stock_summary':
          return 'satguru_daily_stock_summary';
        default:
          return `satguru_${baseName}`;
      }
    }
    
    // Default to DKEGL tables (original tables)
    return baseName;
  };

  const isSatguru = organization?.code === 'SATGURU';
  const isDKEGL = organization?.code === 'DKEGL';

  const value = {
    organization,
    isLoading,
    switchOrganization,
    getTableName,
    isSatguru,
    isDKEGL
  };

  return (
    <OrganizationContext.Provider value={value}>
      {children}
    </OrganizationContext.Provider>
  );
};