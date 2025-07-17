import { useOrganization } from '@/contexts/OrganizationContext';
import { supabase } from '@/integrations/supabase/client';

export const useOrganizationData = () => {
  const { getTableName, isSatguru, organization, isLoading } = useOrganization();
  
  console.log('🏢 useOrganizationData called - Organization:', organization?.name || 'none', 'isSatguru:', isSatguru, 'isLoading:', isLoading);

  return {
    getTableName,
    
    // Categories queries
    getCategories: async () => {
      const query = isSatguru 
        ? supabase.from('satguru_categories' as any).select('*').order('category_name')
        : supabase.from('categories').select('*').order('category_name');
      
      const { data, error } = await query;
      if (error) throw error;
      return data || [];
    },

    // Item master queries
    getItems: async () => {
      const query = isSatguru
        ? supabase
            .from('satguru_item_master' as any)
            .select('*, satguru_categories!inner(category_name)')
            .order('item_code')
        : supabase
            .from('item_master')
            .select('*, categories!inner(category_name)')
            .order('item_code');
      
      const { data, error } = await query;
      if (error) throw error;
      return data || [];
    },

    // Stock queries
    getStock: async () => {
      const query = isSatguru
        ? supabase.from('satguru_stock' as any).select('*').order('item_code')
        : supabase.from('stock').select('*').order('item_code');
      
      const { data, error } = await query;
      if (error) throw error;
      return data || [];
    },

    // Stock summary view
    getStockSummary: async () => {
      const query = isSatguru
        ? supabase.from('satguru_stock_summary' as any).select('*')
        : supabase.from('stock_summary').select('*');
      
      const { data, error } = await query;
      if (error) throw error;
      return data || [];
    },

    // GRN log queries
    getGRNLog: async () => {
      const query = isSatguru
        ? supabase.from('satguru_grn_log' as any).select('*').order('grn_date', { ascending: false })
        : supabase.from('grn_log').select('*').order('grn_date', { ascending: false });
      
      const { data, error } = await query;
      if (error) throw error;
      return data || [];
    },

    // Issue log queries
    getIssueLog: async () => {
      const query = isSatguru
        ? supabase.from('satguru_issue_log' as any).select('*').order('issue_date', { ascending: false })
        : supabase.from('issue_log').select('*').order('issue_date', { ascending: false });
      
      const { data, error } = await query;
      if (error) throw error;
      return data || [];
    },

    // Generic query method for raw SQL/RPC calls
    executeQuery: async (query: string, params?: any) => {
      // For now, return a simple error since execute_sql doesn't exist
      throw new Error('Direct SQL execution not available');
    },

    // Insert operations
    insertCategory: async (data: any) => {
      const query = isSatguru 
        ? supabase.from('satguru_categories' as any).insert(data).select()
        : supabase.from('categories').insert(data).select();
      
      const { data: result, error } = await query;
      if (error) throw error;
      return result;
    },

    insertItem: async (data: any) => {
      const query = isSatguru
        ? supabase.from('satguru_item_master' as any).insert(data).select()
        : supabase.from('item_master').insert(data).select();
      
      const { data: result, error } = await query;
      if (error) throw error;
      return result;
    },

    insertStock: async (data: any) => {
      const query = isSatguru
        ? supabase.from('satguru_stock' as any).insert(data).select()
        : supabase.from('stock').insert(data).select();
      
      const { data: result, error } = await query;
      if (error) throw error;
      return result;
    },

    insertGRN: async (data: any) => {
      const query = isSatguru
        ? supabase.from('satguru_grn_log' as any).insert(data).select()
        : supabase.from('grn_log').insert(data).select();
      
      const { data: result, error } = await query;
      if (error) throw error;
      return result;
    },

    insertIssue: async (data: any) => {
      const query = isSatguru
        ? supabase.from('satguru_issue_log' as any).insert(data).select()
        : supabase.from('issue_log').insert(data).select();
      
      const { data: result, error } = await query;
      if (error) throw error;
      return result;
    },

    // Update operations
    updateCategory: async (id: string, data: any) => {
      const query = isSatguru 
        ? supabase.from('satguru_categories' as any).update(data).eq('id', id).select()
        : supabase.from('categories').update(data).eq('id', id).select();
      
      const { data: result, error } = await query;
      if (error) throw error;
      return result;
    },

    updateItem: async (id: string, data: any) => {
      const query = isSatguru
        ? supabase.from('satguru_item_master' as any).update(data).eq('id', id).select()
        : supabase.from('item_master').update(data).eq('id', id).select();
      
      const { data: result, error } = await query;
      if (error) throw error;
      return result;
    },

    updateStock: async (itemCode: string, data: any) => {
      const query = isSatguru
        ? supabase.from('satguru_stock' as any).update(data).eq('item_code', itemCode).select()
        : supabase.from('stock').update(data).eq('item_code', itemCode).select();
      
      const { data: result, error } = await query;
      if (error) throw error;
      return result;
    },

    // Delete operations
    deleteCategory: async (id: string) => {
      const query = isSatguru 
        ? supabase.from('satguru_categories' as any).delete().eq('id', id)
        : supabase.from('categories').delete().eq('id', id);
      
      const { error } = await query;
      if (error) throw error;
      return true;
    },

    deleteItem: async (id: string) => {
      const query = isSatguru
        ? supabase.from('satguru_item_master' as any).delete().eq('id', id)
        : supabase.from('item_master').delete().eq('id', id);
      
      const { error } = await query;
      if (error) throw error;
      return true;
    }
  };
};