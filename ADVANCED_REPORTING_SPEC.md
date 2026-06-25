# 🎯 Advanced Order Intelligence & Reporting — Technical Specification (v1.0)

**Loyiha**: Tozalash Markazi CRM — Kengaytirilgan Buyurtmalar Tahlili va Hisoboti  
**Versiya**: 1.0  
**Sana**: 2026-06-21  
**Mumavvil**: Chief System Analyst & UI/UX Expert  

---

## 📋 FIHRIST

1. [GLOBAL FILTRLAR VA VAQTNI TAQQOSLASH](#1-global-filtrlar-va-vaqtni-taqqoslash)
2. [KENGAYTIRILGAN KPI VA TREND KARTALARI](#2-kengaytirilgan-kpi-va-trend-kartalari)
3. [KENGAYTIRILGAN STATUSLAR VIZUAL FUNNELI](#3-kengaytirilgan-statuslar-vizual-funneli)
4. [MATEMATIK VA LOGIC ALGORITMLARI](#4-matematik-va-logic-algoritmlari)
5. [ASOSIY BUYURTMALAR JADVALI](#5-asosiy-buyurtmalar-jadvali)
6. [AQLLI INSAYTLAR VA ALERT GENERATORI](#6-aqlli-insaytlar-va-alert-generatori)

---

## 1. GLOBAL FILTRLAR VA VAQTNI TAQQOSLASH

### 1.1 Date Picker Rejimlari (Predefined Modes)

```javascript
const DATE_PICKER_MODES = {
  'bugun': { 
    label: '📅 Bugun', 
    calculate: () => {
      const today = new Date();
      return { 
        from: toDateKey(today), 
        to: toDateKey(today),
        prevFrom: toDateKey(addDays(today, -1)),
        prevTo: toDateKey(addDays(today, -1))
      };
    }
  },
  'kecha': { 
    label: '⬅️ Kecha',
    calculate: () => {
      const yesterday = addDays(new Date(), -1);
      return { 
        from: toDateKey(yesterday), 
        to: toDateKey(yesterday),
        prevFrom: toDateKey(addDays(yesterday, -1)),
        prevTo: toDateKey(addDays(yesterday, -1))
      };
    }
  },
  'hafta_7': { 
    label: '📆 Oxirgi 7 kun',
    calculate: () => {
      const today = new Date();
      const from = toDateKey(addDays(today, -6));
      const to = toDateKey(today);
      const prevFrom = toDateKey(addDays(today, -13));
      const prevTo = toDateKey(addDays(today, -7));
      return { from, to, prevFrom, prevTo };
    }
  },
  'oy_30': { 
    label: '📊 Oxirgi 30 kun',
    calculate: () => {
      const today = new Date();
      const from = toDateKey(addDays(today, -29));
      const to = toDateKey(today);
      const prevFrom = toDateKey(addDays(today, -59));
      const prevTo = toDateKey(addDays(today, -30));
      return { from, to, prevFrom, prevTo };
    }
  },
  'joriy_oy': { 
    label: '📈 Joriy Oy',
    calculate: () => {
      const today = new Date();
      const from = new Date(today.getFullYear(), today.getMonth(), 1);
      const to = today;
      const prevMonthStart = new Date(today.getFullYear(), today.getMonth() - 1, 1);
      const prevMonthEnd = new Date(today.getFullYear(), today.getMonth(), 0);
      return {
        from: toDateKey(from),
        to: toDateKey(to),
        prevFrom: toDateKey(prevMonthStart),
        prevTo: toDateKey(prevMonthEnd)
      };
    }
  },
  'joriy_kvartal': { 
    label: '🔷 Joriy Kvartal',
    calculate: () => {
      const today = new Date();
      const quarter = Math.floor(today.getMonth() / 3);
      const from = new Date(today.getFullYear(), quarter * 3, 1);
      const to = today;
      const prevQuarterStart = new Date(today.getFullYear(), (quarter - 1) * 3, 1);
      const prevQuarterEnd = new Date(today.getFullYear(), quarter * 3, 0);
      return {
        from: toDateKey(from),
        to: toDateKey(to),
        prevFrom: toDateKey(prevQuarterStart),
        prevTo: toDateKey(prevQuarterEnd)
      };
    }
  },
  'joriy_yil': { 
    label: '📅 Joriy Yil',
    calculate: () => {
      const today = new Date();
      const from = new Date(today.getFullYear(), 0, 1);
      const to = today;
      const prevYearStart = new Date(today.getFullYear() - 1, 0, 1);
      const prevYearEnd = new Date(today.getFullYear() - 1, 11, 31);
      return {
        from: toDateKey(from),
        to: toDateKey(to),
        prevFrom: toDateKey(prevYearStart),
        prevTo: toDateKey(prevYearEnd)
      };
    }
  },
  'custom': { 
    label: '🎯 Erkin Muddat',
    calculate: (fromDate, toDate) => {
      const from = toDateKey(new Date(fromDate));
      const to = toDateKey(new Date(toDate));
      
      // O'tgan davr: ayni shu uzunlikdagi period
      const diffDays = daysBetween(new Date(fromDate), new Date(toDate));
      const prevTo = addDays(new Date(fromDate), -1);
      const prevFrom = addDays(prevTo, -diffDays);
      
      return {
        from,
        to,
        prevFrom: toDateKey(prevFrom),
        prevTo: toDateKey(prevTo)
      };
    }
  }
};
```

### 1.2 Taqqoslash Algoritmi (Comparison Logic)

```javascript
/**
 * Ikkala davr uchun ma'lumotlarni solishtirish
 * Har bir KPI uchun: Joriy % va O'tgan % ni hisoblash
 */
function compareMetrics(currentData, previousData) {
  return {
    current: {
      orders: currentData.length,
      revenue: currentData.reduce((s, o) => s + o.total, 0),
      avgCheck: currentData.reduce((s, o) => s + o.total, 0) / (currentData.length || 1),
      deliveredCount: currentData.filter(o => o.status === 'yetkazildi').length,
      cancelledCount: currentData.filter(o => o.status === 'bekor').length
    },
    previous: {
      orders: previousData.length,
      revenue: previousData.reduce((s, o) => s + o.total, 0),
      avgCheck: previousData.reduce((s, o) => s + o.total, 0) / (previousData.length || 1),
      deliveredCount: previousData.filter(o => o.status === 'yetkazildi').length,
      cancelledCount: previousData.filter(o => o.status === 'bekor').length
    }
  };
}

/**
 * Foiz o'sish/pasayish formulasi
 * Formula: ((Joriy - O'tgan) / O'tgan) * 100
 * Agar O'tgan = 0, natija = Joriy > 0 ? +100 : 0
 */
function calculateDeltaPercent(current, previous) {
  if (previous === 0) {
    return current > 0 ? 100 : 0;
  }
  return ((current - previous) / Math.abs(previous)) * 100;
}
```

### 1.3 Multi-Filtrlash Matrisasi

```javascript
/**
 * Bir vaqtda ko'p filtrlash arxitekturasi
 */
const FILTER_DIMENSIONS = {
  status: {
    label: 'Holati',
    values: ['qabul', 'yuvish', 'quritish', 'tayyor', 'yetkazildi', 'bekor']
  },
  courier: {
    label: 'Kuryer',
    values: [] // Dinamikdan tolinadi
  },
  paymentType: {
    label: "To'lov Turi",
    values: ['naqd', 'karta', 'otkazma', 'nasiya']
  },
  carpetType: {
    label: 'Gilam Turi',
    values: ['oriental', 'shag', 'ikebana', 'boshqa']
  },
  region: {
    label: 'Hudud/Sektor',
    values: [] // Dinamikdan tolinadi
  }
};

/**
 * Filtrlash funksiyasi
 */
function applyMultiFilters(orders, filters) {
  return orders.filter(order => {
    // Status filteri
    if (filters.status && filters.status.length > 0) {
      if (!filters.status.includes(order.status)) return false;
    }
    
    // Kuryer filteri
    if (filters.courier && filters.courier.length > 0) {
      if (!filters.courier.includes(order.courierId)) return false;
    }
    
    // To'lov turi filteri
    if (filters.paymentType && filters.paymentType.length > 0) {
      if (!filters.paymentType.includes(order.paymentType)) return false;
    }
    
    // Gilam turi filteri
    if (filters.carpetType && filters.carpetType.length > 0) {
      if (!filters.carpetType.includes(order.carpetType)) return false;
    }
    
    // Hudud filteri (address-dan ekstrakt qilish)
    if (filters.region && filters.region.length > 0) {
      const region = extractRegionFromAddress(order.address);
      if (!filters.region.includes(region)) return false;
    }
    
    return true;
  });
}
```

---

## 2. KENGAYTIRILGAN KPI VA TREND KARTALARI

### 2.1 KPI Kartalarining Jadvali

| # | KPI Nomi | Matematik Formula | O'tgan Davr | Komponent | Status |
|---|----------|------------------|-----------|-----------|--------|
| 1 | Sof Daromad | SUM(orders.total) | Avg O'tgan Davr | `KpiCard` | ✅ |
| 2 | Yuvilgan M² | SUM(orders.quantity WHERE product='gilam') | O'rtacha | `TrendCard` | ✅ |
| 3 | Unumdorlik % | (Delivered / Total) * 100 | % O'sish | `MetricCard` | ✅ |
| 4 | O'rtacha Chek | SUM(total) / COUNT(orders) | Eski O'rtacha | `TrendCard` | ✅ |
| 5 | Yangi Mijozlar | COUNT(DISTINCT customers) WHERE createdAt IN [range] | Eski Soni | `StatCard` | 🔄 |
| 6 | Doimiy Mijozlar | COUNT(DISTINCT customers) WHERE repeat_count > 1 | Eski Soni | `RetentionCard` | 🔄 |
| 7 | SLA Nisbati | (OnTime / Total) * 100 | O'tgan % | `SlaCard` | 🔄 |
| 8 | Kechik O'rtacha | AVG(deliveredAt - createdAt) hours | O'tgan Avg | `DelayCard` | 🔄 |

### 2.2 KPI Card Komponenti Strukturasi

```javascript
/**
 * KPI Card komponenti — statik struktura
 * Har bir KPI uchun: Taqqoslash + Ikonka + Rang
 */
const KPI_CONFIG = {
  revenue: {
    id: 'revenue',
    label: 'Sof Daromad',
    icon: '💰',
    unit: 'sum',
    formula: (orders) => orders.reduce((s, o) => s + o.total, 0),
    compare: true,
    threshold: { good: 5000000, warning: 2000000 },
    trend: 'up' // 'up' yoki 'down'
  },
  
  sqmWashed: {
    id: 'sqm',
    label: "Yuvilgan M²",
    icon: '📏',
    unit: 'm²',
    formula: (orders) => orders.reduce((s, o) => s + (o.product === 'gilam' ? o.quantity : 0), 0),
    compare: true,
    threshold: { good: 1000, warning: 500 }
  },
  
  efficiency: {
    id: 'efficiency',
    label: 'Yetkazish Unumdorlik',
    icon: '✅',
    unit: '%',
    formula: (orders) => {
      const delivered = orders.filter(o => o.status === 'yetkazildi').length;
      return orders.length > 0 ? (delivered / orders.length) * 100 : 0;
    },
    compare: true,
    threshold: { good: 95, warning: 85 }
  },

  avgCheck: {
    id: 'avgcheck',
    label: "O'rtacha Chek",
    icon: '📊',
    unit: 'sum',
    formula: (orders) => {
      const total = orders.reduce((s, o) => s + o.total, 0);
      return orders.length > 0 ? total / orders.length : 0;
    },
    compare: true,
    threshold: { good: 500000, warning: 300000 }
  },

  newCustomers: {
    id: 'newcustomers',
    label: 'Yangi Mijozlar',
    icon: '👤',
    unit: 'ta',
    formula: (orders, customers) => {
      const newCustIds = new Set();
      orders.forEach(o => {
        if (customers.find(c => c.phone === o.phone && isNewCustomer(c))) {
          newCustIds.add(o.phone);
        }
      });
      return newCustIds.size;
    },
    compare: true,
    threshold: { good: 20, warning: 10 }
  }
};

/**
 * KPI Card render funksiyasi
 */
function renderKpiCard(config, currentValue, previousValue) {
  const deltaPercent = calculateDeltaPercent(currentValue, previousValue);
  const isPositive = deltaPercent >= 0;
  const arrow = isPositive ? '📈' : '📉';
  const color = isPositive ? '#10B981' : '#EF4444';
  
  const html = `
    <div class="kpi-card" style="border-left: 4px solid ${color}">
      <div class="kpi-header">
        <span class="kpi-icon">${config.icon}</span>
        <span class="kpi-label">${config.label}</span>
      </div>
      <div class="kpi-value">
        ${formatMoney(currentValue)} ${config.unit}
      </div>
      <div class="kpi-trend" style="color: ${color}">
        ${arrow} ${Math.abs(deltaPercent).toFixed(1)}% o'tgan davriga nisbatan
      </div>
      <div class="kpi-compare">
        <small>O'tgan: ${formatMoney(previousValue)} ${config.unit}</small>
      </div>
    </div>
  `;
  
  return html;
}
```

---

## 3. KENGAYTIRILGAN STATUSLAR VIZUAL FUNNELI

### 3.1 Status Pipeline Bosqichlari

```javascript
const ORDER_PIPELINE = [
  { 
    id: 'new',
    label: '🆕 Yangi Buyurtma', 
    dbStatus: 'qabul',
    color: '#3B82F6'
  },
  { 
    id: 'courier_on_way',
    label: '🚚 Kuryer Yo\'lda',
    dbStatus: 'yo_lda',
    color: '#8B5CF6'
  },
  { 
    id: 'pickup_complete',
    label: '✋ Olib Kelindi',
    dbStatus: 'olib_kelindi',
    color: '#06B6D4'
  },
  { 
    id: 'washing',
    label: '🧴 Yuvish Jarayoni',
    dbStatus: 'yuvish',
    color: '#F59E0B'
  },
  { 
    id: 'drying',
    label: '💨 Quritish',
    dbStatus: 'quritish',
    color: '#EC4899'
  },
  { 
    id: 'packing',
    label: '📦 Qadoqlash',
    dbStatus: 'tayyor',
    color: '#A78BFA'
  },
  { 
    id: 'in_delivery',
    label: '🚗 Yetkazishda',
    dbStatus: 'yetkazildi_yo_lda',
    color: '#06B6D4'
  },
  { 
    id: 'completed',
    label: '✅ Yakunlandi',
    dbStatus: 'yetkazildi',
    color: '#10B981'
  }
];
```

### 3.2 Bottleneck (Tiqilinch) Analizi

```javascript
/**
 * Har bir status bosqichi uchun o'rtacha vaqtni hisoblash
 * Bottleneck = Agar order bu statusda NORMAL NORMADAN ko'p vaqt turibdi
 */

// NORMAL normalar (soatlar cinsidan)
const STAGE_SLA = {
  'yuvish': 24,      // 24 soat
  'quritish': 12,    // 12 soat
  'tayyor': 2,       // Qadoqlash 2 soat
  'yetkazildi': 48   // Yetkazish 48 soat
};

function calculateBottlenecks(orders, range) {
  const bottlenecks = {};
  
  ORDER_PIPELINE.forEach(stage => {
    const stageOrders = orders.filter(o => o.status === stage.dbStatus);
    
    if (stageOrders.length === 0) {
      bottlenecks[stage.id] = { count: 0, avgHours: 0, isBottleneck: false };
      return;
    }
    
    // O'rtacha vaqtni hisoblash
    const totalHours = stageOrders.reduce((sum, order) => {
      const createdTime = new Date(order.createdAt);
      const currentTime = new Date();
      const hours = (currentTime - createdTime) / (1000 * 60 * 60);
      return sum + hours;
    }, 0);
    
    const avgHours = totalHours / stageOrders.length;
    const sla = STAGE_SLA[stage.dbStatus] || 24;
    const isBottleneck = avgHours > sla * 1.2; // 120% normani oshsa
    
    bottlenecks[stage.id] = {
      count: stageOrders.length,
      avgHours: avgHours.toFixed(1),
      sla: sla,
      isBottleneck: isBottleneck,
      financialLoad: stageOrders.reduce((s, o) => s + o.total, 0),
      percentOverSla: isBottleneck ? (((avgHours - sla) / sla) * 100).toFixed(1) : 0
    };
  });
  
  return bottlenecks;
}

/**
 * Funnel render funksiyasi — SVG yoki HTML tabletka
 */
function renderOrderFunnel(bottlenecks) {
  let html = '<div class="funnel-container">';
  
  ORDER_PIPELINE.forEach((stage, idx) => {
    const data = bottlenecks[stage.id];
    const percent = ((ORDER_PIPELINE[0].count - data.count) / ORDER_PIPELINE[0].count * 100).toFixed(1);
    
    const warningClass = data.isBottleneck ? 'bottleneck-alert' : '';
    const bottleneckMsg = data.isBottleneck 
      ? `⚠️ ${data.percentOverSla}% NORM OSHDI (O'rtacha ${data.avgHours}h)`
      : `✓ Normal`;
    
    html += `
      <div class="funnel-stage ${warningClass}" style="background-color: ${stage.color}22; border-left: 4px solid ${stage.color}">
        <div class="stage-header">
          <strong>${stage.label}</strong>
          <span class="stage-count">${data.count} ta</span>
        </div>
        <div class="stage-details">
          <small>${bottleneckMsg}</small>
          <small>💰 ${formatMoney(data.financialLoad)}</small>
        </div>
        <div class="stage-bar" style="width: ${percent}%"></div>
      </div>
    `;
  });
  
  html += '</div>';
  return html;
}
```

---

## 4. MATEMATIK VA LOGIC ALGORITMLARI

### 4.1 Taqqoslash Uchun SQL Logikasi (PostgreSQL)

```sql
-- Joriy davr vs O'tgan davr ma'lumotlarini bitta so'rovda
WITH current_period AS (
  SELECT 
    COUNT(*) as order_count,
    SUM(total) as total_revenue,
    AVG(total) as avg_check,
    COUNT(CASE WHEN status = 'yetkazildi' THEN 1 END) as delivered_count,
    COUNT(CASE WHEN EXTRACT(EPOCH FROM (delivered_at - created_at))/3600 > 48 
             THEN 1 END) as delayed_count
  FROM tm_orders
  WHERE DATE(created_at) >= $1 AND DATE(created_at) <= $2
),

previous_period AS (
  SELECT 
    COUNT(*) as order_count,
    SUM(total) as total_revenue,
    AVG(total) as avg_check,
    COUNT(CASE WHEN status = 'yetkazildi' THEN 1 END) as delivered_count,
    COUNT(CASE WHEN EXTRACT(EPOCH FROM (delivered_at - created_at))/3600 > 48 
             THEN 1 END) as delayed_count
  FROM tm_orders
  WHERE DATE(created_at) >= $3 AND DATE(created_at) <= $4
)

SELECT 
  -- Joriy davr
  c.order_count as current_orders,
  c.total_revenue as current_revenue,
  c.avg_check as current_avg_check,
  c.delivered_count as current_delivered,
  
  -- O'tgan davr
  p.order_count as previous_orders,
  p.total_revenue as previous_revenue,
  p.avg_check as previous_avg_check,
  p.delivered_count as previous_delivered,
  
  -- DELTA % HISOBLASH
  CASE 
    WHEN p.order_count = 0 THEN (CASE WHEN c.order_count > 0 THEN 100 ELSE 0 END)
    ELSE ROUND(((c.order_count - p.order_count)::NUMERIC / p.order_count * 100), 2)
  END as orders_delta_percent,
  
  CASE 
    WHEN p.total_revenue = 0 THEN (CASE WHEN c.total_revenue > 0 THEN 100 ELSE 0 END)
    ELSE ROUND(((c.total_revenue - p.total_revenue)::NUMERIC / p.total_revenue * 100), 2)
  END as revenue_delta_percent,
  
  CASE 
    WHEN p.avg_check = 0 THEN (CASE WHEN c.avg_check > 0 THEN 100 ELSE 0 END)
    ELSE ROUND(((c.avg_check - p.avg_check)::NUMERIC / p.avg_check * 100), 2)
  END as avg_check_delta_percent

FROM current_period c, previous_period p;
```

### 4.2 Foiz O'sish Formulasi (JavaScript)

```javascript
/**
 * DIVISION BY ZERO XATOSI OLDINI OLISH
 */
function safeCalculateDelta(current, previous) {
  // Agar avvalgisi 0 bo'lsa
  if (!previous || previous === 0) {
    // Joriy > 0 bo'lsa: 100% o'sish (va)
    // Joriy = 0 bo'lsa: 0% (o'zgarish yo'q)
    return current > 0 ? 100 : 0;
  }
  
  const delta = ((current - previous) / Math.abs(previous)) * 100;
  
  // NaN yoki Infinity boshqarish
  if (!isFinite(delta)) return 0;
  
  return delta;
}

// MISOL
console.log(safeCalculateDelta(1000, 500));      // 100
console.log(safeCalculateDelta(500, 1000));      // -50
console.log(safeCalculateDelta(100, 0));         // 100 (yangi kelib chiqqan)
console.log(safeCalculateDelta(0, 100));         // -100
console.log(safeCalculateDelta(0, 0));           // 0
```

### 4.3 Bottleneck Hisoblash Algoritmi

```javascript
/**
 * Status bosqichida o'rtacha qolish vaqtini hisoblash
 */
function calculateAverageStageTime(orders, status) {
  const stageOrders = orders.filter(o => o.status === status);
  
  if (stageOrders.length === 0) return 0;
  
  const totalMs = stageOrders.reduce((sum, order) => {
    const entryTime = new Date(order.createdAt);
    const exitTime = order.statusChangedAt 
      ? new Date(order.statusChangedAt[status])
      : new Date();
    
    return sum + (exitTime - entryTime);
  }, 0);
  
  const avgMs = totalMs / stageOrders.length;
  const avgHours = avgMs / (1000 * 60 * 60);
  
  return avgHours;
}
```

---

## 5. ASOSIY BUYURTMALAR JADVALI

### 5.1 Datatable Ustunlari va Skanerlash

| Ustun | Tur | Kenglik | Tavsif | Filter |
|-------|-----|---------|--------|--------|
| ID | Text | 60px | Buyurtma ID | ❌ |
| Mijoz | Text | 140px | Familya + Ism | Qidirish |
| Telefon | Tel | 120px | Telefon raqam | Link |
| Gilam/M² | Number | 100px | Miqdori + Tur | ❌ |
| Status | Badge | 120px | Rang bilan | Filtrlash |
| Kuryer | Text | 120px | Kuryer nomi | Filtrlash |
| Umumiy | Money | 120px | Jami narx (sum) | ❌ |
| To'lov | Badge | 110px | Naqd/Karta/Nasiya | Filtrlash |
| Muddat | Time | 90px | Yaratilish vaqti | ❌ |
| Actions | Buttons | 150px | Ko'rish/Tahrif | ❌ |

### 5.2 Datatable HTML Strukturasi

```html
<div class="datatable-container">
  <!-- Filters Row -->
  <div class="datatable-filters">
    <input type="text" placeholder="Qidirish..." class="search-input" oninput="filterTable()">
    <select onchange="filterByStatus()">
      <option value="">Barcha Holatlar</option>
      <option value="qabul">Qabul</option>
      <!-- ... -->
    </select>
    <button onclick="exportToCSV()">📥 CSV Export</button>
    <button onclick="exportToExcel()">📥 Excel Export</button>
    <button onclick="exportToPDF()">📥 PDF Export</button>
  </div>
  
  <!-- Actual Table -->
  <table class="datatable" id="ordersTable">
    <thead>
      <tr>
        <th>ID</th>
        <th>Mijoz</th>
        <th>Telefon</th>
        <th>Mahsulot</th>
        <th>Holati</th>
        <th>Kuryer</th>
        <th>Umumiy</th>
        <th>To'lov</th>
        <th>Vaqti</th>
        <th>Amallar</th>
      </tr>
    </thead>
    <tbody id="ordersBody">
      <!-- Dinamikdan tolinadi -->
    </tbody>
  </table>
</div>
```

---

## 6. AQLLI INSAYTLAR VA ALERT GENERATORI

### 6.1 Alert Rules Matrix

```javascript
const INSIGHT_RULES = [
  {
    id: 'cancelled_spike',
    name: 'Bekor Buyurtmalar Oshishi',
    condition: (delta) => delta.cancelledPercent > 15,
    message: (delta) => 
      `⚠️ Diqqat! Oxirgi ${delta.period} kunda bekor qilingan buyurtmalar soni ${delta.cancelledPercent.toFixed(1)}% ga oshdi. 
       Asosiy sabab: [SYSTEM GENERATED - CRM uchun sabab tahlili kerak]`,
    severity: 'high',
    color: '#EF4444'
  },
  
  {
    id: 'delay_increase',
    name: 'Yetkazish Kechikishi',
    condition: (delta) => delta.avgDelayDeltaPercent > 10,
    message: (delta) =>
      `⚠️ Yetkazish vaqti o'tgan davriga nisbatan ${delta.avgDelayDeltaPercent.toFixed(1)}% ga oshdi. 
       Hozir: ${delta.currentAvgDelay}h, O'tgan: ${delta.previousAvgDelay}h`,
    severity: 'high',
    color: '#F59E0B'
  },
  
  {
    id: 'revenue_growth',
    name: 'Daromad O'sishi',
    condition: (delta) => delta.revenueDeltaPercent > 20,
    message: (delta) =>
      `✅ Juda yaxshi! Daromad ${delta.revenueDeltaPercent.toFixed(1)}% ga oshdi. Joriy: ${formatMoney(delta.currentRevenue)}`,
    severity: 'success',
    color: '#10B981'
  },
  
  {
    id: 'bottleneck_detected',
    name: 'Tiqilinch Aniqlandi',
    condition: (bottleneck) => bottleneck.isBottleneck,
    message: (bottleneck) =>
      `⚠️ '${bottleneck.stageName}' bosqichida tiqilinch! O'rtacha ${bottleneck.avgHours}h turadi (Norm: ${bottleneck.sla}h)`,
    severity: 'warning',
    color: '#F59E0B'
  },
  
  {
    id: 'new_customers_below_target',
    name: 'Yangi Mijozlar Maqsadidan Kam',
    condition: (kpi) => kpi.newCustomersCount < kpi.newCustomersTarget,
    message: (kpi) =>
      `📉 Yangi mijozlar soni maqsadidan ${kpi.deficit} ta kam (Maqsad: ${kpi.target}, Joriy: ${kpi.current})`,
    severity: 'warning',
    color: '#F59E0B'
  }
];

/**
 * Alert Generator — Har bir period uchun avto-generatsiya
 */
function generateInsights(metrics, bottlenecks) {
  const insights = [];
  
  INSIGHT_RULES.forEach(rule => {
    let triggered = false;
    let message = '';
    
    if (rule.id.includes('bottleneck')) {
      // Bottleneck rules
      Object.values(bottlenecks).forEach(bn => {
        if (bn.isBottleneck && rule.condition(bn)) {
          triggered = true;
          message = rule.message(bn);
        }
      });
    } else {
      // Metrics rules
      if (rule.condition(metrics)) {
        triggered = true;
        message = rule.message(metrics);
      }
    }
    
    if (triggered) {
      insights.push({
        id: rule.id,
        name: rule.name,
        message: message,
        severity: rule.severity,
        color: rule.color,
        timestamp: new Date().toISOString()
      });
    }
  });
  
  return insights;
}

/**
 * Insight Alert UI Komponent
 */
function renderInsightAlert(insight) {
  const iconMap = {
    high: '🔴',
    warning: '🟡',
    success: '🟢'
  };
  
  return `
    <div class="insight-alert" style="background-color: ${insight.color}15; border-left: 4px solid ${insight.color}">
      <div class="insight-icon">${iconMap[insight.severity]}</div>
      <div class="insight-content">
        <strong>${insight.name}</strong>
        <p>${insight.message}</p>
        <small>${new Date(insight.timestamp).toLocaleString('uz-UZ')}</small>
      </div>
      <button class="insight-close" onclick="dismissInsight('${insight.id}')">×</button>
    </div>
  `;
}
```

---

## FRONTEND STRUKTURA (localStorage-da)

```javascript
const ANALYTICS_SCHEMA = {
  // Current period snapshot
  analytics_current: {
    period: 'oy_30',
    dateRange: { from: 'YYYY-MM-DD', to: 'YYYY-MM-DD' },
    snapshot: {
      orders: 0,
      revenue: 0,
      avgCheck: 0,
      delivered: 0,
      cancelled: 0,
      avgDeliveryTime: 0,
      newCustomers: 0,
      repeatCustomers: 0
    },
    bottlenecks: { /* ... */ },
    insights: [ /* ... */ ]
  },

  // Previous period snapshot (for comparison)
  analytics_previous: {
    snapshot: { /* ... */ }
  },

  // Time filter state
  analytics_filter_state: {
    mode: 'oy_30',
    customFrom: null,
    customTo: null,
    multiFilters: {
      status: [],
      courier: [],
      paymentType: [],
      carpetType: [],
      region: []
    }
  }
};
```

---

## KOMPONENTLAR IMPLEMENTATSIYA CHECKLIST

- [ ] **TimePickerWidget** — Date range selector
- [ ] **KpiCardGrid** — 4-8 ta KPI karta gridda
- [ ] **MetricsComparison** — Joriy vs O'tgan solishtirma
- [ ] **OrderFunnel** — Status pipeline visuali
- [ ] **BottleneckAlert** — Tiqilinch aniqlash va oomali
- [ ] **OrdersDataTable** — Asosiy buyurtmalar jadvali
- [ ] **InsightAlerts** — AI-generated alerts paneli
- [ ] **ExportModule** — CSV/Excel/PDF export
- [ ] **DashboardHeader** — Umumiy shakl va filtrlar

---

## DASTURCHI VA'DALARI

1. Barcha foiz hisoblashlarida **Division by Zero** xatolarini oldini olish
2. Dinamik sora ba'zi vaqt millisekundlarda bo'lishi mumkin — caching qo'llash
3. Mobile responsivligi (md breakpoint'dan keyin jadvalni ketma-ketlikka o'tkazish)
4. Aralash ranglar (gradients) bo'yicha murakkab alertlar uchun CSS variables ishlatish
5. localStorage limit 5MB — katta ma'lumotlar turli muhitga (IndexedDB) o'tkazish

---

**Spec Versiya**: 1.0 ✅  
**Keyingi Qadamlar**: Frontend komponenti ishlab chiqish va DB integratsiyasi

