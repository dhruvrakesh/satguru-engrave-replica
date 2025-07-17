import { useOrganization } from '@/contexts/OrganizationContext';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from './use-toast';

export const useOrganizationData = () => {
  const { getTableName, isSatguru } = useOrganization();
  const { toast } = useToast();

  const handleError = (error: Error, context: string) => {
    console.error(`Error in ${context}:`, error);
    toast({
      title: `Error fetching ${context}`,
      description: error.message,
      variant: "destructive"
    });
    throw error;
  };

  return {
    getTableName,
    
    getCategories: async () => {
      const { data, error } = await (supabase as any).from(getTableName('categories')).select('*').order('category_name');
      if (error) handleError(error, 'categories');
      return data || [];
    },

    getItems: async () => {
      const query = isSatguru
        ? (supabase as any).from(getTableName('item_master')).select('*, satguru_categories(category_name)')
        : (supabase as any).from(getTableName('item_master')).select('*, categories(category_name)');
      
      const { data, error } = await query.order('item_code');
      if (error) handleError(error, 'items');
      return data || [];
    },

    getStock: async () => {
      const { data, error } = await (supabase as any).from(getTableName('stock')).select('*').order('item_code');
      if (error) handleError(error, 'stock');
      return data || [];
    },
    
    getStockSummary: async () => {
      const { data, error } = await (supabase as any).from(getTableName('stock_summary')).select('*');
      if (error) handleError(error, 'stock summary');
      return data || [];
    },

    getGRNLog: async () => {
      const { data, error } = await (supabase as any).from(getTableName('grn_log')).select('*, item_master(item_name)').order('created_at', { ascending: false });
      if (error) handleError(error, 'grn log');
      return data || [];
    },

    getIssueLog: async () => {
      const { data, error } = await (supabase as any).from(getTableName('issue_log')).select('*, item_master(item_name)').order('created_at', { ascending: false });
      if (error) handleError(error, 'issue log');
      return data || [];
    },

    insertCategory: async (categoryData: any) => {
      const { data, error } = await (supabase as any).from(getTableName('categories')).insert(categoryData).select();
      if (error) handleError(error, 'inserting category');
      return data;
    },

    insertItem: async (itemData: any) => {
      const { data, error } = await (supabase as any).from(getTableName('item_master')).insert(itemData).select();
      if (error) handleError(error, 'inserting item');
      return data;
    },
    
    insertStock: async (stockData: any) => {
      const { error } = await (supabase as any).from(getTableName('stock')).upsert(stockData);
      if (error) handleError(error, 'inserting stock');
    },

    insertGRN: async (grnData: any) => {
      const { data, error } = await (supabase as any).from(getTableName('grn_log')).insert(grnData).select();
      if (error) handleError(error, 'inserting GRN');
      return data;
    },

    insertIssue: async (issueData: any) => {
      const { data, error } = await (supabase as any).from(getTableName('issue_log')).insert(issueData).select();
      if (error) handleError(error, 'inserting issue');
      return data;
    },

    updateCategory: async (categoryId: string, categoryData: any) => {
      const { data, error } = await (supabase as any).from(getTableName('categories')).update(categoryData).eq('id', categoryId).select();
      if (error) handleError(error, 'updating category');
      return data;
    },

    deleteCategory: async (categoryId: string) => {
      const { error } = await (supabase as any).from(getTableName('categories')).delete().eq('id', categoryId);
      if (error) handleError(error, 'deleting category');
    },

    updateItem: async (itemId: string, itemData: any) => {
      const { data, error } = await (supabase as any).from(getTableName('item_master')).update(itemData).eq('id', itemId).select();
      if (error) handleError(error, 'updating item');
      return data;
    },

    deleteItem: async (itemId: string) => {
      const { error } = await (supabase as any).from(getTableName('item_master')).delete().eq('id', itemId);
      if (error) handleError(error, 'deleting item');
    },
  };
};