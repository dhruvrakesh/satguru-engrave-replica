import React, { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { TableCell, TableRow } from "@/components/ui/table";
import { Edit, Save, X, Trash2 } from "lucide-react";
import { toast } from "@/hooks/use-toast";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

interface GRNData {
  id: string;
  grn_date: string | null;
  grn_number: string;
  item_code: string;
  qty_received: number;
  supplier: string | null;
  total_value: number | null;
  unit_price: number | null;
  remarks: string | null;
}

interface EditableGRNRowProps {
  grn: GRNData;
  onEdit?: () => void;
  onCancel?: () => void;
}

export const EditableGRNRow: React.FC<EditableGRNRowProps> = ({ grn }) => {
  const [isEditing, setIsEditing] = useState(false);
  const [editData, setEditData] = useState(grn);
  const queryClient = useQueryClient();

  const updateMutation = useMutation({
    mutationFn: async (data: Partial<GRNData>) => {
      const { error } = await supabase
        .from('grn_log')
        .update(data)
        .eq('id', grn.id);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recent-grn'] });
      setIsEditing(false);
      toast({
        title: "Success",
        description: "GRN entry updated successfully",
      });
    },
    onError: (error) => {
      toast({
        title: "Error",
        description: `Failed to update GRN: ${error.message}`,
        variant: "destructive",
      });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: async () => {
      const { error } = await supabase
        .from('grn_log')
        .delete()
        .eq('id', grn.id);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recent-grn'] });
      toast({
        title: "Success",
        description: "GRN entry deleted successfully",
      });
    },
    onError: (error) => {
      toast({
        title: "Error",
        description: `Failed to delete GRN: ${error.message}`,
        variant: "destructive",
      });
    },
  });

  const handleSave = () => {
    if (editData.qty_received <= 0) {
      toast({
        title: "Validation Error",
        description: "Quantity must be greater than 0",
        variant: "destructive",
      });
      return;
    }

    updateMutation.mutate({
      grn_date: editData.grn_date,
      grn_number: editData.grn_number,
      qty_received: editData.qty_received,
      supplier: editData.supplier,
      total_value: editData.total_value,
      unit_price: editData.unit_price,
      remarks: editData.remarks,
    });
  };

  const handleCancel = () => {
    setEditData(grn);
    setIsEditing(false);
  };

  if (isEditing) {
    return (
      <TableRow>
        <TableCell>
          <Input
            type="date"
            value={editData.grn_date || ''}
            onChange={(e) => setEditData({...editData, grn_date: e.target.value})}
          />
        </TableCell>
        <TableCell>
          <Input
            value={editData.grn_number}
            onChange={(e) => setEditData({...editData, grn_number: e.target.value})}
          />
        </TableCell>
        <TableCell>{editData.item_code}</TableCell>
        <TableCell>
          <Input
            type="number"
            value={editData.qty_received}
            onChange={(e) => setEditData({...editData, qty_received: Number(e.target.value)})}
          />
        </TableCell>
        <TableCell>
          <Input
            value={editData.supplier || ''}
            onChange={(e) => setEditData({...editData, supplier: e.target.value})}
          />
        </TableCell>
        <TableCell>
          <Input
            type="number"
            value={editData.unit_price || ''}
            onChange={(e) => setEditData({...editData, unit_price: Number(e.target.value)})}
          />
        </TableCell>
        <TableCell>
          <Input
            type="number"
            value={editData.total_value || ''}
            onChange={(e) => setEditData({...editData, total_value: Number(e.target.value)})}
          />
        </TableCell>
        <TableCell>
          <Input
            value={editData.remarks || ''}
            onChange={(e) => setEditData({...editData, remarks: e.target.value})}
          />
        </TableCell>
        <TableCell>
          <div className="flex gap-2">
            <Button
              size="sm"
              onClick={handleSave}
              disabled={updateMutation.isPending}
            >
              <Save className="h-4 w-4" />
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={handleCancel}
            >
              <X className="h-4 w-4" />
            </Button>
          </div>
        </TableCell>
      </TableRow>
    );
  }

  return (
    <TableRow>
      <TableCell>{grn.grn_date}</TableCell>
      <TableCell>{grn.grn_number}</TableCell>
      <TableCell>{grn.item_code}</TableCell>
      <TableCell>{grn.qty_received}</TableCell>
      <TableCell>{grn.supplier || '-'}</TableCell>
      <TableCell>{grn.unit_price || '-'}</TableCell>
      <TableCell>{grn.total_value || '-'}</TableCell>
      <TableCell>{grn.remarks || '-'}</TableCell>
      <TableCell>
        <div className="flex gap-2">
          <Button
            size="sm"
            variant="outline"
            onClick={() => setIsEditing(true)}
          >
            <Edit className="h-4 w-4" />
          </Button>
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button size="sm" variant="destructive">
                <Trash2 className="h-4 w-4" />
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>Delete GRN Entry</AlertDialogTitle>
                <AlertDialogDescription>
                  Are you sure you want to delete this GRN entry? This will reverse the stock addition and cannot be undone.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Cancel</AlertDialogCancel>
                <AlertDialogAction
                  onClick={() => deleteMutation.mutate()}
                  disabled={deleteMutation.isPending}
                  className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                >
                  Delete
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        </div>
      </TableCell>
    </TableRow>
  );
};