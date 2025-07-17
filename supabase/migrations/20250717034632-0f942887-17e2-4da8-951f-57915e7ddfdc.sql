-- Create missing stock_summary view for DKEGL
CREATE OR REPLACE VIEW public.stock_summary AS
SELECT 
    im.item_code,
    im.item_name,
    c.category_name,
    COALESCE(s.current_qty, 0) as current_qty,
    COALESCE(s.opening_qty, 0) as opening_qty,
    COALESCE(s.current_qty, 0) as calculated_qty, -- For now, same as current
    COALESCE(grn_totals.total_grn_qty, 0) as total_grn_qty,
    COALESCE(issue_totals.total_issued_qty, 0) as total_issued_qty,
    COALESCE(issue_30d.issue_30d, 0) as issue_30d,
    CASE 
        WHEN COALESCE(issue_30d.issue_30d, 0) = 0 THEN 999999
        ELSE COALESCE(s.current_qty, 0) / NULLIF(COALESCE(issue_30d.issue_30d, 0) / 30.0, 0)
    END as days_of_cover,
    CASE 
        WHEN COALESCE(s.current_qty, 0) = COALESCE(s.current_qty, 0) THEN 'OK'
        ELSE 'MISMATCH'
    END as stock_validation_status,
    s.last_updated,
    im.id as item_id,
    c.id as category_id
FROM public.item_master im
LEFT JOIN public.categories c ON im.category_id = c.id
LEFT JOIN public.stock s ON im.item_code = s.item_code
LEFT JOIN (
    SELECT 
        item_code,
        SUM(qty_received) as total_grn_qty
    FROM public.grn_log
    GROUP BY item_code
) grn_totals ON im.item_code = grn_totals.item_code
LEFT JOIN (
    SELECT 
        item_code,
        SUM(qty_issued) as total_issued_qty
    FROM public.issue_log
    GROUP BY item_code
) issue_totals ON im.item_code = issue_totals.item_code
LEFT JOIN (
    SELECT 
        item_code,
        SUM(qty_issued) as issue_30d
    FROM public.issue_log
    WHERE issue_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY item_code
) issue_30d ON im.item_code = issue_30d.item_code
WHERE im.is_active = true
ORDER BY im.item_name;

-- Create RLS policy for stock_summary view
CREATE POLICY "Users can view stock_summary" ON public.stock_summary FOR SELECT USING (true);

-- Grant permissions
GRANT SELECT ON public.stock_summary TO authenticated;