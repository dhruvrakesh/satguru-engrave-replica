import React from 'react';
import { useOrganization } from '@/contexts/OrganizationContext';
import { useAuth } from '@/contexts/AuthContext';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { LogOut, Building2 } from 'lucide-react';

export const OrganizationHeader = () => {
  const { organization, isLoading } = useOrganization();
  const { signOut, user } = useAuth();

  if (isLoading) {
    return (
      <div className="flex items-center gap-2">
        <div className="h-6 w-20 bg-muted animate-pulse rounded"></div>
      </div>
    );
  }

  return (
    <div className="flex items-center gap-3">
      {organization && (
        <div className="flex items-center gap-2">
          <Building2 className="h-4 w-4 text-muted-foreground" />
          <Badge variant={organization.code === 'SATGURU' ? 'default' : 'secondary'}>
            {organization.name}
          </Badge>
        </div>
      )}
      
      <div className="text-sm text-muted-foreground">
        {user?.email}
      </div>
      
      <Button
        variant="ghost"
        size="sm"
        onClick={signOut}
        className="h-8 px-2"
      >
        <LogOut className="h-4 w-4" />
      </Button>
    </div>
  );
};