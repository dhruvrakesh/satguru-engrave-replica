import { useQuery } from "@tanstack/react-query"
import { useOrganization } from "@/contexts/OrganizationContext"
import { useOrganizationData } from "@/hooks/useOrganizationData"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Package, TrendingUp, AlertTriangle, ShoppingCart, BarChart3, PieChart } from "lucide-react"
import { ChartContainer, ChartTooltip, ChartTooltipContent, ChartLegend, ChartLegendContent } from "@/components/ui/chart"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, ResponsiveContainer, PieChart as RechartsPieChart, Pie, Cell, LineChart, Line, Area, AreaChart } from "recharts"

const Dashboard = () => {
  const { organization, isLoading: orgLoading, isSatguru } = useOrganization()
  const { getStockSummary, getGRNLog, getIssueLog } = useOrganizationData();

  console.log('📊 Dashboard rendering - Org:', organization?.name || 'none', 'isSatguru:', isSatguru, 'orgLoading:', orgLoading)

  // Show organization loading state
  if (orgLoading) {
    return (
      <div className="p-6 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
          <p>Loading organization data...</p>
        </div>
      </div>
    )
  }

  // Show if organization not found
  if (!organization) {
    return (
      <div className="p-6 flex items-center justify-center">
        <div className="text-center">
          <p className="text-destructive">Organization not found</p>
          <p className="text-sm text-muted-foreground">Please contact support if this issue persists.</p>
        </div>
      </div>
    )
  }

  const { data: stockSummary } = useQuery({
    queryKey: ['organization-stock-summary', organization.code, isSatguru],
    enabled: !!organization,
    queryFn: async () => {
      console.log('📊 Fetching stock summary for org:', organization.name, 'isSatguru:', isSatguru)
      const response = await getStockSummary();
      return response?.data || [];
    }
  })

  const { data: recentGRNs } = useQuery({
    queryKey: ['organization-recent-grns', organization.code, isSatguru],
    enabled: !!organization,
    queryFn: async () => {
      console.log('📊 Fetching recent GRNs for org:', organization.name, 'isSatguru:', isSatguru)
      const response = await getGRNLog();
      return response?.data?.slice(0, 5) || [];
    }
  })

  const { data: recentIssues } = useQuery({
    queryKey: ['organization-recent-issues', organization.code, isSatguru],
    enabled: !!organization,
    queryFn: async () => {
      console.log('📊 Fetching recent issues for org:', organization.name, 'isSatguru:', isSatguru)
      const response = await getIssueLog();
      return response?.data?.slice(0, 5) || [];
    }
  })

  const { data: stockMovements } = useQuery({
    queryKey: ['organization-stock-movements', organization.code, isSatguru],
    enabled: !!organization,
    queryFn: async () => {
      console.log('📊 Fetching stock movements for org:', organization.name, 'isSatguru:', isSatguru)
      const [grnResponse, issueResponse] = await Promise.all([
        getGRNLog(),
        getIssueLog()
      ]);
      
      const grnData = grnResponse?.data || [];
      const issueData = issueResponse?.data || [];
      
      // Group by date and sum quantities
      const movementMap = new Map()
      
      grnData.slice(0, 30).forEach(item => {
        const date = item.grn_date || item.date
        if (!movementMap.has(date)) {
          movementMap.set(date, { date, grn: 0, issues: 0 })
        }
        movementMap.get(date).grn += item.qty_received || 0
      })
      
      issueData.slice(0, 30).forEach(item => {
        const date = item.issue_date || item.date
        if (!movementMap.has(date)) {
          movementMap.set(date, { date, grn: 0, issues: 0 })
        }
        movementMap.get(date).issues += item.qty_issued || 0
      })
      
      return Array.from(movementMap.values()).sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
    }
  })

  const safeStockSummary = (stockSummary || []).filter(item => item && typeof item === 'object') as any[];
  
  const totalItems = safeStockSummary.length
  const lowStockItems = safeStockSummary.filter(item => (item?.current_qty || 0) < 10).length
  const totalValue = safeStockSummary.reduce((sum, item) => sum + (item?.current_qty || 0), 0)

  // Process data for charts
  const categoryData = safeStockSummary.reduce((acc, item) => {
    const category = item?.category_name || item?.categories?.category_name || 'Uncategorized'
    if (!acc[category]) {
      acc[category] = { name: category, value: 0, items: 0 }
    }
    acc[category].value += item?.current_qty || 0
    acc[category].items += 1
    return acc
  }, {} as Record<string, { name: string; value: number; items: number }>)

  const categoryChartData = Object.values(categoryData || {})
  
  const stockLevelDistribution = [
    { name: 'High Stock (100+)', value: safeStockSummary.filter(item => (item?.current_qty || 0) >= 100).length, color: '#10B981' },
    { name: 'Medium Stock (10-99)', value: safeStockSummary.filter(item => (item?.current_qty || 0) >= 10 && (item?.current_qty || 0) < 100).length, color: '#F59E0B' },
    { name: 'Low Stock (<10)', value: safeStockSummary.filter(item => (item?.current_qty || 0) < 10).length, color: '#EF4444' },
    { name: 'Zero Stock', value: safeStockSummary.filter(item => (item?.current_qty || 0) === 0).length, color: '#6B7280' }
  ]

  const chartConfig = {
    grn: {
      label: "GRN Received",
      color: "hsl(var(--chart-1))"
    },
    issues: {
      label: "Issues",
      color: "hsl(var(--chart-2))"
    }
  }

  const getDaysOfCoverBadge = (days: number | null) => {
    if (!days) return <Badge variant="secondary">N/A</Badge>
    if (days > 30) return <Badge variant="default" className="bg-green-100 text-green-800">Good ({days.toFixed(0)} days)</Badge>
    if (days > 10) return <Badge variant="secondary" className="bg-yellow-100 text-yellow-800">Medium ({days.toFixed(0)} days)</Badge>
    return <Badge variant="destructive">Low ({days.toFixed(0)} days)</Badge>
  }

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-3xl font-bold">ERP Dashboard - {organization.name}</h1>
        <p className="text-muted-foreground">Overview of your inventory management system</p>
        <div className="mt-2">
          <Badge variant={isSatguru ? "default" : "secondary"}>
            {organization.code}
          </Badge>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Items</CardTitle>
            <Package className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalItems}</div>
            <p className="text-xs text-muted-foreground">Active inventory items</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Low Stock Alert</CardTitle>
            <AlertTriangle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">{lowStockItems}</div>
            <p className="text-xs text-muted-foreground">Items below threshold</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Stock Qty</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalValue.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">Units in inventory</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Recent Transactions</CardTitle>
            <ShoppingCart className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{(recentGRNs?.length || 0) + (recentIssues?.length || 0)}</div>
            <p className="text-xs text-muted-foreground">Last 5 entries</p>
          </CardContent>
        </Card>
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Stock Movement Trends */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <BarChart3 className="mr-2 h-4 w-4" />
              Stock Movement Trends
            </CardTitle>
            <CardDescription>Daily GRN vs Issues over last 30 days</CardDescription>
          </CardHeader>
          <CardContent>
            <ChartContainer config={chartConfig} className="h-[300px]">
              <AreaChart data={stockMovements}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis 
                  dataKey="date" 
                  tickFormatter={(value) => new Date(value).toLocaleDateString()}
                />
                <YAxis />
                <ChartTooltip content={<ChartTooltipContent />} />
                <ChartLegend content={<ChartLegendContent />} />
                <Area 
                  type="monotone" 
                  dataKey="grn" 
                  stackId="1" 
                  stroke="var(--color-grn)" 
                  fill="var(--color-grn)" 
                  fillOpacity={0.6}
                />
                <Area 
                  type="monotone" 
                  dataKey="issues" 
                  stackId="2" 
                  stroke="var(--color-issues)" 
                  fill="var(--color-issues)" 
                  fillOpacity={0.6}
                />
              </AreaChart>
            </ChartContainer>
          </CardContent>
        </Card>

        {/* Stock Level Distribution */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <PieChart className="mr-2 h-4 w-4" />
              Stock Level Distribution
            </CardTitle>
            <CardDescription>Items distribution by stock levels</CardDescription>
          </CardHeader>
          <CardContent>
            <ChartContainer config={{}} className="h-[300px]">
              <RechartsPieChart>
                <Pie
                  data={stockLevelDistribution}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, value }) => `${name}: ${value}`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {stockLevelDistribution.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <ChartTooltip content={<ChartTooltipContent />} />
              </RechartsPieChart>
            </ChartContainer>
          </CardContent>
        </Card>
      </div>

      {/* Category Analysis */}
      <Card>
        <CardHeader>
          <CardTitle>Category-wise Stock Analysis</CardTitle>
          <CardDescription>Stock distribution and item count by category</CardDescription>
        </CardHeader>
        <CardContent>
          <ChartContainer config={{}} className="h-[400px]">
            <BarChart data={categoryChartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <ChartTooltip content={<ChartTooltipContent />} />
              <Bar dataKey="value" fill="hsl(var(--chart-1))" name="Stock Quantity" />
              <Bar dataKey="items" fill="hsl(var(--chart-2))" name="Item Count" />
            </BarChart>
          </ChartContainer>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Stock Status */}
        <Card>
          <CardHeader>
            <CardTitle>Stock Status</CardTitle>
            <CardDescription>Current inventory levels and days of cover</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {safeStockSummary.slice(0, 10).map((item, index) => (
                <div key={item?.item_code || index} className="flex items-center justify-between p-2 border rounded">
                  <div>
                    <p className="font-medium">{item?.item_name || item?.item_master?.item_name || 'Unknown Item'}</p>
                    <p className="text-sm text-muted-foreground">Code: {item?.item_code || 'N/A'}</p>
                  </div>
                  <div className="text-right space-y-1">
                    <p className="font-mono">{item?.current_qty || 0}</p>
                    {getDaysOfCoverBadge(item?.days_of_cover)}
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Recent Activity */}
        <Card>
          <CardHeader>
            <CardTitle>Recent Activity</CardTitle>
            <CardDescription>Latest GRN and Issue transactions</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {recentGRNs?.map((grn) => (
                <div key={grn.id} className="flex items-center justify-between p-2 border rounded bg-green-50">
                  <div>
                    <p className="font-medium text-green-800">GRN: {grn.grn_number}</p>
                    <p className="text-sm text-muted-foreground">{grn.item_master?.item_name}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-mono text-green-600">+{grn.qty_received}</p>
                    <p className="text-xs text-muted-foreground">{new Date(grn.date).toLocaleDateString()}</p>
                  </div>
                </div>
              ))}
              
              {recentIssues?.map((issue) => (
                <div key={issue.id} className="flex items-center justify-between p-2 border rounded bg-red-50">
                  <div>
                    <p className="font-medium text-red-800">Issue: {issue.purpose}</p>
                    <p className="text-sm text-muted-foreground">{issue.item_master?.item_name}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-mono text-red-600">-{issue.qty_issued}</p>
                    <p className="text-xs text-muted-foreground">{new Date(issue.date).toLocaleDateString()}</p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export default Dashboard