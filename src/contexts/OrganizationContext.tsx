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
      setIsLoading(true);
      console.log('Fetching organization for user ID:', user.id, 'Email:', user.email);
      
      // First, get the profile with organization_id
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('organization_id, role, is_approved')
        .eq('id', user.id)
        .maybeSingle();

      if (profileError) {
        console.error('Error fetching profile:', profileError);
        setIsLoading(false);
        return;
      }

      if (!profile) {
        // Profile doesn't exist, create one
        console.log('Profile not found, attempting to create one...');
        
        // Determine organization based on email domain
        const isSatguru = user.email?.includes('@satguruengravures.com');
        const isDKEGL = user.email?.includes('@dkenterprises.co.in');
        
        if (isSatguru || isDKEGL) {
          const orgCode = isSatguru ? 'SATGURU' : 'DKEGL';
          console.log('Assigning user to organization:', orgCode);
          
          // Get organization ID
          const { data: org, error: orgError } = await supabase
            .from('organizations')
            .select('id')
            .eq('code', orgCode)
            .single();
          
          if (orgError) {
            console.error('Error fetching organization:', orgError);
            setIsLoading(false);
            return;
          }
          
          if (org) {
            // Create profile
            const { error: insertError } = await supabase
              .from('profiles')
              .insert({
                id: user.id,
                email: user.email,
                employee_id: `TEMP_${user.id.substring(0, 8)}`,
                organization_id: org.id,
                is_approved: true, // Auto-approve admin users
                role: 'admin',
                full_name: user.user_metadata?.full_name || 'Admin User'
              });
            
            if (insertError) {
              console.error('Error creating profile:', insertError);
              setIsLoading(false);
              return;
            }
            
            console.log('Profile created successfully');
            // Recursively call to fetch the newly created profile
            fetchUserOrganization();
            return;
          }
        } else {
          console.error('User email not recognized for any organization');
          setIsLoading(false);
          return;
        }
      }

      // Now fetch the organization details separately
      if (profile?.organization_id) {
        console.log('Fetching organization details for ID:', profile.organization_id);
        
        const { data: organization, error: orgError } = await supabase
          .from('organizations')
          .select('*')
          .eq('id', profile.organization_id)
          .single();

        if (orgError) {
          console.error('Error fetching organization:', orgError);
        } else {
          console.log('Organization loaded successfully:', organization.name, organization.code);
          setOrganization(organization);
        }
      } else {
        console.error('Profile exists but no organization_id found');
      }

    } catch (error) {
      console.error('Unexpected error in fetchUserOrganization:', error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (user?.email) {
      console.log('Loading organization for user:', user.email);
      fetchUserOrganization();
    } else {
      console.log('No authenticated user, clearing organization');
      setOrganization(null);
      setIsLoading(false);
    }
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