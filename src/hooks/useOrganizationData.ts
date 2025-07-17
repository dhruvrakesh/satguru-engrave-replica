import { useOrganization } from '@/contexts/OrganizationContext';
import { supabase } from '@/integrations/supabase/client';

export const useOrganizationData = () => {
  const { getTableName, isSatguru } = useOrganization();

  return {
    getTableName,
    
    // Categories queries
    getCategories: () => {
      if (isSatguru) {
        return supabase.from('satguru_categories' as any).select('*').order('category_name');
      }
      return supabase.from('categories').select('*').order('category_name');
    },

    // Item master queries
    getItems: () => {
      if (isSatguru) {
        return supabase
          .from('satguru_item_master' as any)
          .select('*, satguru_categories!inner(category_name)')
          .order('item_code');
      }
      return supabase
        .from('item_master')
        .select('*, categories!inner(category_name)')
        .order('item_code');
    },

    // Stock queries
    getStock: () => {
      if (isSatguru) {
        return supabase.from('satguru_stock' as any).select('*').order('item_code');
      }
      return supabase.from('stock').select('*').order('item_code');
    },

    // Stock summary view
    getStockSummary: () => {
      if (isSatguru) {
        return supabase.from('satguru_stock_summary' as any).select('*').order('item_code');
      }
      return supabase.from('stock_summary').select('*').order('item_code');
    },

    // GRN log queries
    getGRNLog: () => {
      if (isSatguru) {
        return supabase.from('satguru_grn_log' as any).select('*').order('date', { ascending: false });
      }
      return supabase.from('grn_log').select('*').order('date', { ascending: false });
    },

    // Issue log queries
    getIssueLog: () => {
      if (isSatguru) {
        return supabase.from('satguru_issue_log' as any).select('*').order('date', { ascending: false });
      }
      return supabase.from('issue_log').select('*').order('date', { ascending: false });
    },

    // Generic query method for raw SQL/RPC calls
    executeQuery: (query: string, params?: any) => {
      return supabase.rpc('execute_sql', { sql: query, params });
    },

    // Insert operations
    insertCategory: (data: any) => {
      if (isSatguru) {
        return supabase.from('satguru_categories' as any).insert(data);
      }
      return supabase.from('categories').insert(data);
    },

    insertItem: (data: any) => {
      if (isSatguru) {
        return supabase.from('satguru_item_master' as any).insert(data);
      }
      return supabase.from('item_master').insert(data);
    },

    insertStock: (data: any) => {
      if (isSatguru) {
        return supabase.from('satguru_stock' as any).insert(data);
      }
      return supabase.from('stock').insert(data);
    },

    insertGRN: (data: any) => {
      if (isSatguru) {
        return supabase.from('satguru_grn_log' as any).insert(data);
      }
      return supabase.from('grn_log').insert(data);
    },

    insertIssue: (data: any) => {
      if (isSatguru) {
        return supabase.from('satguru_issue_log' as any).insert(data);
      }
      return supabase.from('issue_log').insert(data);
    },

    // Update operations
    updateCategory: (id: string, data: any) => {
      if (isSatguru) {
        return supabase.from('satguru_categories' as any).update(data).eq('id', id);
      }
      return supabase.from('categories').update(data).eq('id', id);
    },

    updateItem: (id: string, data: any) => {
      if (isSatguru) {
        return supabase.from('satguru_item_master' as any).update(data).eq('id', id);
      }
      return supabase.from('item_master').update(data).eq('id', id);
    },

    updateStock: (itemCode: string, data: any) => {
      if (isSatguru) {
        return supabase.from('satguru_stock' as any).update(data).eq('item_code', itemCode);
      }
      return supabase.from('stock').update(data).eq('item_code', itemCode);
    },

    // Delete operations
    deleteCategory: (id: string) => {
      if (isSatguru) {
        return supabase.from('satguru_categories' as any).delete().eq('id', id);
      }
      return supabase.from('categories').delete().eq('id', id);
    },

    deleteItem: (id: string) => {
      if (isSatguru) {
        return supabase.from('satguru_item_master' as any).delete().eq('id', id);
      }
      return supabase.from('item_master').delete().eq('id', id);
    }
  };
};