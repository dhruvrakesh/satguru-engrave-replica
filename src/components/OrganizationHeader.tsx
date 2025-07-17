import { useOrganization } from "@/contexts/OrganizationContext";
import { Badge } from "@/components/ui/badge";

export const OrganizationHeader = () => {
  const { organization, isSatguru, isDKEGL } = useOrganization();

  if (!organization) return null;

  return (
    <div className="flex items-center gap-3 p-4 border-b bg-background/50">
      <div>
        <h1 className="text-xl font-semibold text-foreground">
          {organization.name}
        </h1>
        <p className="text-sm text-muted-foreground">
          {isSatguru && "Flexible Packaging ERP System"}
          {isDKEGL && "Inventory Management System"}
        </p>
      </div>
      <Badge variant={isSatguru ? "default" : "secondary"} className="ml-auto">
        {organization.code}
      </Badge>
    </div>
  );
};