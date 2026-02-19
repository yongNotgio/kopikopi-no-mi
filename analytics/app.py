# ============================================================
# ☕ Coffee Bean Quality Analytics Dashboard
# Streamlit App — Powered by the Full Pipeline
# Place this file alongside coffee_bean_quality_dataset.sql
# Run: streamlit run app.py
# ============================================================

import re, warnings
import numpy as np
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import streamlit as st
from datetime import datetime, timedelta

from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import GradientBoostingRegressor, RandomForestRegressor
from sklearn.linear_model import Ridge
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

warnings.filterwarnings("ignore")

# ── Page Config ───────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="☕ Coffee Bean Quality Analytics",
    page_icon="☕",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ── Constants ─────────────────────────────────────────────────────────────────
ROBUSTA_IDEALS = {
    "elevation_m":      (600,  1200),
    "avg_temp_c":       (13,   26),
    "avg_humidity_pct": (75,   85),
    "avg_rainfall_mm":  (150,  250),
    "soil_ph":          (5.6,  6.5),
    "pruning_interval_months": (10, 18),
    "bean_moisture":    (10.5, 12.5),
}
FERT_FREQ_MAP = {"never": 0, "rarely": 1, "sometimes": 2, "often": 3}
PEST_FREQ_MAP = {"never": 0, "rarely": 1, "sometimes": 2, "often": 3}
FERT_TYPE_MAP = {"none": 0, "organic": 1, "non-organic": 2, "both": 3}
PEST_TYPE_MAP = {"none": 0, "organic": 1, "non-organic": 2, "both": 3}
STATUS_COLORS = {
    "Critical Drop (>20%)":  "#d62728",
    "Moderate Drop (5-20%)": "#ff7f0e",
    "Stable (±5%)":          "#2ca02c",
    "Improvement (>5%)":     "#1f77b4",
}

ML_FEATURES = [
    "plant_age_months", "pre_yield_kg", "pruning_interval_months",
    "shade_binary", "fert_type_enc", "fert_freq_enc", "pest_type_enc", "pest_freq_enc",
    "mgmt_score", "soil_ph", "avg_temp_c", "avg_rainfall_mm", "avg_humidity_pct",
    "elevation_m", "planting_density", "climate_stress", "season_idx",
    "previous_fine_pct", "previous_premium_pct", "previous_commercial_pct"
]

GRADE_COLORS = {"Fine": "#1B5E20", "Premium": "#66BB6A", "Commercial": "#C8E6C9"}

RECOMMENDATIONS = [
    ("soil_ph", 5.6, 6.5,
     "Soil pH too low → apply agricultural lime to raise pH toward 5.6–6.5.",
     "Soil pH too high → apply sulfur amendments to lower pH toward 5.6–6.5.", "High"),
    ("avg_temp_c", 13, 26,
     "Temperature below optimum → consider windbreaks; monitor frost risk.",
     "Temperature above optimum → increase shade tree cover to cool canopy.", "Medium"),
    ("avg_rainfall_mm", 150, 250,
     "Rainfall below optimum → supplement with irrigation during dry months.",
     "Rainfall above optimum → improve drainage; monitor fungal disease risk.", "Medium"),
    ("avg_humidity_pct", 75, 85,
     "Humidity too low → mulch around base; add shade trees.",
     "Humidity too high → improve airflow; apply preventive fungicide.", "Medium"),
    ("elevation_m", 600, 1200,
     "Elevation below Robusta ideal → consider Excelsa or lower-altitude variety.",
     "Elevation above Robusta ideal → assess suitability; may suit Arabica instead.", "Low"),
    ("pruning_interval_months", 10, 18,
     "Pruning overdue (> 18 months) → prune immediately after harvest for vigour.",
     "Pruning too frequent (< 10 months) → allow full recovery between cycles.", "High"),
    ("fert_freq_enc", 2, 3,
     "Fertilizer too infrequent → increase to at least 1×/year (sometimes).",
     None, "High"),
    ("pest_freq_enc", 1, 3,
     "Pesticide never applied → establish a pest monitoring schedule.",
     None, "Low"),
    ("bean_moisture", 10.5, 12.5,
     "Bean moisture too low → review drying duration; risk of brittle beans.",
     "Bean moisture too high → extend drying; risk of mould and grade downgrade.", "High"),
]

# ═════════════════════════════════════════════════════════════════════════════
# DATA LOADING
# ═════════════════════════════════════════════════════════════════════════════

def split_csv_row(row_str):
    values, current, in_q = [], [], False
    for ch in row_str:
        if ch == "'" and not in_q:
            in_q = True
        elif ch == "'" and in_q:
            in_q = False
        elif ch == "," and not in_q:
            values.append("".join(current).strip().strip("'"))
            current = []
            continue
        current.append(ch)
    values.append("".join(current).strip().strip("'"))
    return values

def parse_table(sql_text, table_name):
    pattern = (
        r"INSERT\s+INTO\s+(?:public\.)?{t}\s*"
        r"\(([^)]+)\)\s*VALUES\s*(.*?)(?=INSERT\s+INTO|--\s*VERIF|$)"
    ).format(t=re.escape(table_name))
    matches = re.findall(pattern, sql_text, re.DOTALL | re.IGNORECASE)
    all_rows = []
    for cols_raw, vals_block in matches:
        cols = [c.strip() for c in cols_raw.split(",")]
        # Allow one level of nesting to handle SQL functions like NOW()
        row_tuples = re.findall(r"\(((?:[^()]*|\([^()]*\))*)\)", vals_block)
        for tup in row_tuples:
            vals = split_csv_row(tup)
            if len(vals) == len(cols):
                all_rows.append(dict(zip(cols, vals)))
    df = pd.DataFrame(all_rows)
    df.replace({"NULL": None, "null": None, "": None}, inplace=True)
    return df

@st.cache_data(show_spinner="⏳ Parsing SQL & building analytics table...")
def load_data(sql_text):
    df_users    = parse_table(sql_text, "users")
    df_farms    = parse_table(sql_text, "farms")
    df_clusters = parse_table(sql_text, "clusters")
    df_csd      = parse_table(sql_text, "cluster_stage_data")
    df_hr       = parse_table(sql_text, "harvest_records")
    if df_hr.empty:
        df_hr = pd.DataFrame(columns=["id", "cluster_id", "season", "actual_harvest_date", "yield_kg", "grade_fine", "grade_premium", "grade_commercial", "notes", "recorded_at"])

    def to_num(s): return pd.to_numeric(s, errors="coerce")
    def to_dt(s):  return pd.to_datetime(s, errors="coerce")

    for c in ["farm_area", "elevation_m", "overall_tree_count"]:
        if c in df_farms.columns: df_farms[c] = to_num(df_farms[c])
    for c in ["area_size_sqm", "plant_count"]:
        if c in df_clusters.columns: df_clusters[c] = to_num(df_clusters[c])

    num_csd = ["plant_age_months","number_of_plants","pruning_interval_months",
               "soil_ph","avg_temp_c","avg_rainfall_mm","avg_humidity_pct",
               "pre_yield_kg","pre_grade_fine","pre_grade_premium","pre_grade_commercial",
               "previous_fine_pct","previous_premium_pct","previous_commercial_pct",
               "defect_count","bean_moisture","predicted_yield","pre_total_trees"]
    date_csd = ["date_planted","last_pruned_date","previous_pruned_date",
                "actual_flowering_date","estimated_flowering_date",
                "estimated_harvest_date","actual_harvest_date","pre_last_harvest_date"]
    for c in num_csd:
        if c in df_csd.columns: df_csd[c] = to_num(df_csd[c])
    for c in date_csd:
        if c in df_csd.columns: df_csd[c] = to_dt(df_csd[c])
    for c in ["yield_kg","grade_fine","grade_premium","grade_commercial"]:
        if c in df_hr.columns: df_hr[c] = to_num(df_hr[c])
    df_hr["actual_harvest_date"] = to_dt(df_hr.get("actual_harvest_date"))

    # Ensure df_hr has cluster_id
    if not df_hr.empty and "cluster_id" not in df_hr.columns:
        possible = [c for c in df_hr.columns if "cluster" in c.lower()]
        if possible:
            df_hr = df_hr.rename(columns={possible[0]:"cluster_id"})
        elif len(df_hr.columns) > 1:
            df_hr = df_hr.rename(columns={df_hr.columns[1]:"cluster_id"})

    # Rename columns for indexing
    if not df_farms.empty:
        if "id" in df_farms.columns:
            df_farms = df_farms.rename(columns={"id":"farm_id"})
        elif "farm_id" not in df_farms.columns:
            df_farms = df_farms.rename(columns={df_farms.columns[0]:"farm_id"})
        farm_lu = df_farms.set_index("farm_id")[ ["elevation_m","farm_area","overall_tree_count","farm_name"] ].to_dict("index")
        farm_user_lu = df_farms.set_index("farm_id")[["user_id"]].to_dict("index")
    else:
        farm_lu = {}
        farm_user_lu = {}

    if not df_clusters.empty:
        if "id" in df_clusters.columns:
            df_clusters = df_clusters.rename(columns={"id":"cluster_id"})
        elif "cluster_id" not in df_clusters.columns:
            df_clusters = df_clusters.rename(columns={df_clusters.columns[0]:"cluster_id"})
        cluster_lu = df_clusters.set_index("cluster_id")[ ["farm_id","cluster_name","area_size_sqm","plant_count","variety","plant_stage"] ].to_dict("index")
    else:
        cluster_lu = {}

    # Build farmer name map via users->farms
    if not df_users.empty:
        if "id" in df_users.columns:
            df_users = df_users.rename(columns={"id":"user_id"})
        elif "user_id" not in df_users.columns:
            df_users = df_users.rename(columns={df_users.columns[0]:"user_id"})
        user_lu = df_users.set_index("user_id")[ ["first_name","last_name","municipality","province"] ].to_dict("index")
    else:
        user_lu = {}

    hr = df_hr.copy()
    hr["farm_id"]          = hr["cluster_id"].map(lambda x: cluster_lu.get(x,{}).get("farm_id"))
    hr["cluster_name"]     = hr["cluster_id"].map(lambda x: cluster_lu.get(x,{}).get("cluster_name"))
    hr["area_size_sqm"]    = hr["cluster_id"].map(lambda x: cluster_lu.get(x,{}).get("area_size_sqm"))
    hr["plant_count"]      = hr["cluster_id"].map(lambda x: cluster_lu.get(x,{}).get("plant_count"))
    hr["variety"]          = hr["cluster_id"].map(lambda x: cluster_lu.get(x,{}).get("variety","Robusta"))
    hr["plant_stage"]      = hr["cluster_id"].map(lambda x: cluster_lu.get(x,{}).get("plant_stage"))
    hr["elevation_m"]      = hr["farm_id"].map(lambda x: farm_lu.get(x,{}).get("elevation_m") if x else None)
    hr["farm_area"]        = hr["farm_id"].map(lambda x: farm_lu.get(x,{}).get("farm_area") if x else None)
    hr["farm_name"]        = hr["farm_id"].map(lambda x: farm_lu.get(x,{}).get("farm_name","") if x else "")
    hr["user_id"]          = hr["farm_id"].map(lambda x: farm_user_lu.get(x,{}).get("user_id") if x else None)
    hr["farmer_name"]      = hr["user_id"].map(lambda x: f"{user_lu.get(x,{}).get('first_name','')} {user_lu.get(x,{}).get('last_name','')}".strip() if x else "")
    hr["municipality"]     = hr["user_id"].map(lambda x: user_lu.get(x,{}).get("municipality","") if x else "")
    hr["province"]         = hr["user_id"].map(lambda x: user_lu.get(x,{}).get("province","") if x else "")

    csd_cols = ["cluster_id","season"] + num_csd + date_csd + [
        "fertilizer_type","fertilizer_frequency","pesticide_type","pesticide_frequency",
        "shade_tree_present","shade_tree_species"]
    flat = hr.merge(df_csd[[c for c in csd_cols if c in df_csd.columns]],
                    on=["cluster_id","season"], how="left", suffixes=("","_csd"))

    flat["plant_age_months"] = flat["plant_age_months"].fillna(
        ((flat["actual_harvest_date"] - flat["date_planted"]).dt.days / 30.44).round(0))
    flat["flowering_to_harvest_days"] = (
        flat["actual_harvest_date"] - flat["actual_flowering_date"]).dt.days
    flat["shade_binary"] = (
        flat["shade_tree_present"].astype(str).str.lower()
        .map({"true":1,"1":1,"false":0,"0":0}).fillna(0).astype(int))
    flat["yield_per_tree"] = (flat["yield_kg"] / flat["plant_count"].replace(0, np.nan)).round(3)
    flat["fine_grade_pct"]       = (flat["grade_fine"]       / flat["yield_kg"].replace(0,np.nan)*100).round(2)
    flat["premium_grade_pct"]    = (flat["grade_premium"]     / flat["yield_kg"].replace(0,np.nan)*100).round(2)
    flat["commercial_grade_pct"] = (flat["grade_commercial"]  / flat["yield_kg"].replace(0,np.nan)*100).round(2)
    flat["yield_delta_kg"]  = (flat["yield_kg"] - flat["pre_yield_kg"]).round(2)
    flat["yield_delta_pct"] = (flat["yield_delta_kg"] / flat["pre_yield_kg"].replace(0,np.nan)*100).round(2)
    flat["yield_drop"] = (flat["yield_delta_kg"] < 0).astype(int)
    flat["planting_density"] = (flat["plant_count"] / flat["area_size_sqm"].replace(0,np.nan)).round(4)
    flat["fert_type_enc"] = flat["fertilizer_type"].astype(str).str.lower().str.strip().map(FERT_TYPE_MAP).fillna(0)
    flat["fert_freq_enc"] = flat["fertilizer_frequency"].astype(str).str.lower().str.strip().map(FERT_FREQ_MAP).fillna(0)
    flat["pest_type_enc"] = flat["pesticide_type"].astype(str).str.lower().str.strip().map(PEST_TYPE_MAP).fillna(0)
    flat["pest_freq_enc"] = flat["pesticide_frequency"].astype(str).str.lower().str.strip().map(PEST_FREQ_MAP).fillna(0)
    flat["mgmt_score"] = (flat["fert_freq_enc"]*0.30 + flat["fert_type_enc"]*0.15 +
                          flat["pest_freq_enc"]*0.40 + flat["pest_type_enc"]*0.15)
    flat["climate_stress"] = (
        (flat["avg_temp_c"]-22).abs()*0.3 +
        (flat["avg_rainfall_mm"]-200).abs()*0.005 +
        (flat["soil_ph"]-6.05).abs()*3.0 +
        (flat["avg_humidity_pct"]-80).abs()*0.1)
    season_order = sorted(flat["season"].dropna().unique())
    flat["season_idx"] = flat["season"].map({s:i for i,s in enumerate(season_order)})

    flat["yield_status"] = pd.cut(
        flat["yield_delta_pct"],
        bins=[-np.inf, -20, -5, 5, np.inf],
        labels=["Critical Drop (>20%)","Moderate Drop (5-20%)","Stable (±5%)","Improvement (>5%)"])

    return flat, df_users, df_farms, df_clusters, df_csd

@st.cache_resource(show_spinner="🤖 Training ML models...")
def train_models(flat_df):
    ml = flat_df.copy()
    ml_clean = ml.dropna(subset=ML_FEATURES + ["yield_kg","fine_grade_pct","premium_grade_pct","commercial_grade_pct"])
    if len(ml_clean) < 10:
        return None, None, None, None
    X = ml_clean[ML_FEATURES].values
    y_yield = ml_clean["yield_kg"].values
    X_tr, X_te, y_tr, y_te = train_test_split(X, y_yield, test_size=0.2, random_state=42)
    models = {
        "GBR" : GradientBoostingRegressor(n_estimators=400, learning_rate=0.04, max_depth=4, subsample=0.8, random_state=42),
        "RF"  : RandomForestRegressor(n_estimators=300, max_depth=8, min_samples_leaf=2, random_state=42),
        "Ridge": Pipeline([("scaler", StandardScaler()), ("ridge", Ridge(alpha=10.0))]),
    }
    results = {}
    for name, mdl in models.items():
        mdl.fit(X_tr, y_tr)
        yp = mdl.predict(X_te)
        cv = cross_val_score(mdl, X, y_yield, cv=min(5,len(ml_clean)), scoring="r2")
        results[name] = {"model":mdl,"y_pred":yp,"y_test":y_te,
                         "MAE":round(mean_absolute_error(y_te,yp),2),
                         "RMSE":round(mean_squared_error(y_te,yp)**0.5,2),
                         "R2":round(r2_score(y_te,yp),4),
                         "CV_R2":round(cv.mean(),4)}
    grade_models, grade_metrics = {}, {}
    for target in ["fine_grade_pct","premium_grade_pct","commercial_grade_pct"]:
        yg = ml_clean[target].values
        Xg_tr,Xg_te,yg_tr,yg_te = train_test_split(X, yg, test_size=0.2, random_state=42)
        gm = GradientBoostingRegressor(n_estimators=300, learning_rate=0.04, max_depth=3, random_state=42)
        gm.fit(Xg_tr, yg_tr)
        yg_p = gm.predict(Xg_te)
        cv_g = cross_val_score(gm, X, yg, cv=min(5,len(ml_clean)), scoring="r2")
        grade_models[target] = gm
        grade_metrics[target] = {"model":gm,"y_pred":yg_p,"y_test":yg_te,
                                  "MAE":round(mean_absolute_error(yg_te,yg_p),2),
                                  "R2":round(r2_score(yg_te,yg_p),4),
                                  "CV_R2":round(cv_g.mean(),4)}
    best_name = max(results, key=lambda k: results[k]["R2"])
    imp = pd.Series(results["GBR"]["model"].feature_importances_, index=ML_FEATURES).sort_values(ascending=False)
    return results, grade_models, grade_metrics, imp, best_name, ml_clean

def get_recommendations(row):
    recs = []
    for col, lo, hi, lo_msg, hi_msg, priority in RECOMMENDATIONS:
        val = pd.to_numeric(row.get(col), errors="coerce")
        if pd.isna(val): continue
        if val < lo and lo_msg:
            recs.append({"factor":col,"value":round(val,2),"ideal":f"{lo}–{hi}","recommendation":lo_msg,"priority":priority})
        elif val > hi and hi_msg:
            recs.append({"factor":col,"value":round(val,2),"ideal":f"{lo}–{hi}","recommendation":hi_msg,"priority":priority})
    if str(row.get("shade_tree_present","")).lower() in ("false","0","no","none"):
        recs.append({"factor":"shade_tree_present","value":"absent","ideal":"present",
                     "recommendation":"No shade trees → plant Madre de Cacao or banana to improve grade quality and moisture retention.",
                     "priority":"Medium"})
    return recs

# ═════════════════════════════════════════════════════════════════════════════
# SIDEBAR
# ═════════════════════════════════════════════════════════════════════════════
st.sidebar.title("☕ Kape Analytics")
st.sidebar.caption("Robusta Coffee Bean Quality Dashboard")

uploaded = st.sidebar.file_uploader("📂 Upload SQL file", type=["sql","txt"],
                                     help="Upload coffee_bean_quality_dataset.sql")

# Try default file if none uploaded
sql_text = None
if uploaded:
    sql_text = uploaded.read().decode("utf-8")
    st.sidebar.success(f"✅ Loaded: {uploaded.name}")
else:
    import os
    for candidate in ["coffee_bean_quality_dataset.sql","paste.txt"]:
        if os.path.exists(candidate):
            with open(candidate, "r", encoding="utf-8") as f:
                sql_text = f.read()
            st.sidebar.info(f"📄 Using default: {candidate}")
            break

if not sql_text:
    st.title("☕ Coffee Bean Quality Analytics")
    st.info("👈 Upload your SQL file in the sidebar to begin.")
    st.stop()

flat, df_users, df_farms, df_clusters, df_csd = load_data(sql_text)
season_order = sorted(flat["season"].dropna().unique())

# ── Sidebar filters ────────────────────────────────────────────────────────────
st.sidebar.markdown("---")
st.sidebar.subheader("🔍 Filters")

all_provinces = sorted(flat["province"].dropna().unique()) if "province" in flat.columns else []
sel_province = st.sidebar.multiselect("Province", all_provinces, default=all_provinces)

all_municipalities = sorted(flat[flat["province"].isin(sel_province)]["municipality"].dropna().unique()) if sel_province else sorted(flat["municipality"].dropna().unique())
sel_municipality = st.sidebar.multiselect("Municipality", all_municipalities, default=all_municipalities)

all_farms = sorted(flat[flat["municipality"].isin(sel_municipality)]["farm_name"].dropna().unique()) if "farm_name" in flat.columns else []
sel_farms = st.sidebar.multiselect("Farm", all_farms, default=all_farms)

sel_seasons = st.sidebar.multiselect("Season", season_order, default=season_order)

# Apply filters
filtered = flat.copy()
if sel_province:      filtered = filtered[filtered["province"].isin(sel_province)]
if sel_municipality:  filtered = filtered[filtered["municipality"].isin(sel_municipality)]
if sel_farms and "farm_name" in filtered.columns:
    filtered = filtered[filtered["farm_name"].isin(sel_farms)]
if sel_seasons:       filtered = filtered[filtered["season"].isin(sel_seasons)]

# Sidebar pages
st.sidebar.markdown("---")
PAGES = [
    "📊 Overview",
    "📈 Yield Trends",
    "🎯 Grade Distribution",
    "🔗 Correlation Analysis",
    "🤖 ML Models",
    "⚠️ Yield Drop Detection",
    "🌸 Harvest Date Estimator",
    "💡 Recommendations",
    "🗃️ Raw Data",
]
page = st.sidebar.radio("Navigate", PAGES)

# ═════════════════════════════════════════════════════════════════════════════
# PAGE: OVERVIEW
# ═════════════════════════════════════════════════════════════════════════════
if page == "📊 Overview":
    st.title("☕ Coffee Bean Quality Analytics")
    st.caption("Robusta — Western Visayas + Negros Occidental | Seasons 2021–2025")
    st.markdown("---")

    c1, c2, c3, c4, c5 = st.columns(5)
    with c1:
        st.metric("Total Yield (kg)", f"{filtered['yield_kg'].sum():,.1f}")
    with c2:
        st.metric("Clusters", filtered["cluster_id"].nunique())
    with c3:
        st.metric("Farms", filtered["farm_id"].nunique() if "farm_id" in filtered.columns else "—")
    with c4:
        avg_fine = filtered["fine_grade_pct"].mean()
        st.metric("Avg Fine %", f"{avg_fine:.1f}%" if not np.isnan(avg_fine) else "—")
    with c5:
        drop_pct = (filtered["yield_drop"].sum() / len(filtered) * 100) if len(filtered) else 0
        st.metric("Yield Drop Rate", f"{drop_pct:.1f}%")

    st.markdown("---")
    col1, col2 = st.columns(2)

    # Yield by season bar
    with col1:
        s_agg = filtered.groupby("season")["yield_kg"].agg(["sum","mean"]).reset_index().sort_values("season")
        fig = px.bar(s_agg, x="season", y="sum",
                     title="Total Yield per Season (kg)",
                     labels={"sum":"Total Yield (kg)","season":"Season"},
                     color_discrete_sequence=["#4A7C59"],
                     text_auto=".0f")
        fig.update_traces(textposition="outside")
        fig.update_layout(showlegend=False)
        st.plotly_chart(fig, use_container_width=True)

    # Grade mix pie
    with col2:
        totals = filtered[["grade_fine","grade_premium","grade_commercial"]].sum()
        fig2 = go.Figure(go.Pie(
            labels=["Fine","Premium","Commercial"],
            values=totals.values,
            marker_colors=["#1B5E20","#66BB6A","#C8E6C9"],
            hole=0.4,
            textinfo="label+percent"
        ))
        fig2.update_layout(title="Overall Grade Composition (kg)")
        st.plotly_chart(fig2, use_container_width=True)

    # Farm-level summary table
    st.markdown("### Farm Summary")
    if "farm_name" in filtered.columns:
        farm_summary = (
            filtered.groupby(["farm_name","province","municipality"])
            .agg(clusters=("cluster_id","nunique"),
                 seasons=("season","nunique"),
                 total_yield=("yield_kg","sum"),
                 avg_yield=("yield_kg","mean"),
                 avg_fine=("fine_grade_pct","mean"))
            .round(2).reset_index()
            .rename(columns={"farm_name":"Farm","province":"Province",
                              "municipality":"Municipality","clusters":"Clusters",
                              "seasons":"Seasons","total_yield":"Total Yield (kg)",
                              "avg_yield":"Avg Yield (kg)","avg_fine":"Avg Fine %"})
            .sort_values("Total Yield (kg)", ascending=False)
        )
        st.dataframe(farm_summary, use_container_width=True, hide_index=True)

# ═════════════════════════════════════════════════════════════════════════════
# PAGE: YIELD TRENDS
# ═════════════════════════════════════════════════════════════════════════════
elif page == "📈 Yield Trends":
    st.title("📈 Yield Trends")
    st.markdown("Season-over-season yield performance across all filtered clusters.")

    s_agg = (
        filtered.groupby("season")["yield_kg"]
        .agg(total="sum", mean="mean", std="std", median="median", count="count")
        .reset_index().sort_values("season")
    )

    tab1, tab2, tab3, tab4 = st.tabs(["Total Yield", "Distribution", "Mean Trend", "Per-Cluster Timeline"])

    with tab1:
        fig = px.bar(s_agg, x="season", y="total",
                     title="Total Yield per Season",
                     labels={"total":"Total Yield (kg)","season":"Season"},
                     color_discrete_sequence=["#4A7C59"],
                     text_auto=".1f")
        fig.update_traces(textposition="outside")
        fig.update_layout(xaxis_title="Season", yaxis_title="kg")
        st.plotly_chart(fig, use_container_width=True)

    with tab2:
        fig2 = px.box(filtered.dropna(subset=["yield_kg"]),
                      x="season", y="yield_kg",
                      title="Yield Distribution per Season",
                      color="season",
                      labels={"yield_kg":"Yield (kg)","season":"Season"},
                      points="all")
        fig2.update_layout(showlegend=False)
        st.plotly_chart(fig2, use_container_width=True)

    with tab3:
        fig3 = go.Figure()
        fig3.add_trace(go.Scatter(
            x=s_agg["season"], y=s_agg["mean"],
            mode="lines+markers", name="Mean Yield",
            line=dict(color="#4A7C59", width=2.5),
            marker=dict(size=8)))
        fig3.add_trace(go.Scatter(
            x=s_agg["season"], y=s_agg["median"],
            mode="lines+markers", name="Median",
            line=dict(color="#C62828", width=1.5, dash="dash"),
            marker=dict(size=6)))
        fig3.add_trace(go.Scatter(
            x=list(s_agg["season"]) + list(s_agg["season"])[::-1],
            y=list((s_agg["mean"]+s_agg["std"].fillna(0))) + list((s_agg["mean"]-s_agg["std"].fillna(0)))[::-1],
            fill="toself", fillcolor="rgba(74,124,89,0.15)",
            line=dict(color="rgba(255,255,255,0)"), name="±1 SD"))
        fig3.update_layout(title="Mean & Median Yield Trend ± 1 SD",
                            xaxis_title="Season", yaxis_title="Yield (kg)")
        st.plotly_chart(fig3, use_container_width=True)

    with tab4:
        if "farm_name" in filtered.columns:
            grp_col = st.selectbox("Group by", ["farm_name","cluster_name","province","municipality"])
        else:
            grp_col = "cluster_name"
        pivot = (filtered.groupby(["season", grp_col])["yield_kg"]
                 .mean().reset_index().sort_values("season"))
        fig4 = px.line(pivot, x="season", y="yield_kg", color=grp_col,
                       title=f"Avg Yield per Season by {grp_col.replace('_',' ').title()}",
                       labels={"yield_kg":"Avg Yield (kg)","season":"Season"},
                       markers=True)
        st.plotly_chart(fig4, use_container_width=True)

    st.markdown("### Season Summary Table")
    st.dataframe(s_agg.rename(columns={"season":"Season","total":"Total (kg)",
                                        "mean":"Mean (kg)","std":"Std Dev","median":"Median","count":"Count"})
                      .round(2), use_container_width=True, hide_index=True)

# ═════════════════════════════════════════════════════════════════════════════
# PAGE: GRADE DISTRIBUTION
# ═════════════════════════════════════════════════════════════════════════════
elif page == "🎯 Grade Distribution":
    st.title("🎯 Grade Distribution")
    st.markdown("Bean quality breakdown: Fine, Premium, and Commercial grades.")

    tab1, tab2, tab3, tab4 = st.tabs(["By Season", "Overall Pie", "Fine % Histogram", "Bean Moisture"])

    with tab1:
        grade_s = (filtered.groupby("season")[["fine_grade_pct","premium_grade_pct","commercial_grade_pct"]]
                   .mean().round(2).reset_index().sort_values("season"))
        fig = go.Figure()
        for g, col, color in [("Fine","fine_grade_pct","#1B5E20"),
                               ("Premium","premium_grade_pct","#66BB6A"),
                               ("Commercial","commercial_grade_pct","#C8E6C9")]:
            fig.add_trace(go.Bar(name=g, x=grade_s["season"], y=grade_s[col],
                                 marker_color=color))
        fig.update_layout(barmode="stack", title="Avg Grade % per Season",
                          xaxis_title="Season", yaxis_title="% of Yield",
                          legend_title="Grade")
        st.plotly_chart(fig, use_container_width=True)

    with tab2:
        totals = filtered[["grade_fine","grade_premium","grade_commercial"]].sum()
        fig2 = go.Figure(go.Pie(
            labels=["Fine","Premium","Commercial"],
            values=totals.values,
            marker_colors=["#1B5E20","#66BB6A","#C8E6C9"],
            hole=0.35, textinfo="label+percent+value",
            hovertemplate="%{label}<br>%{value:.2f} kg<br>%{percent}"))
        fig2.update_layout(title=f"Overall Grade Mix — Total {totals.sum():,.1f} kg")
        st.plotly_chart(fig2, use_container_width=True)

    with tab3:
        fig3 = px.histogram(filtered.dropna(subset=["fine_grade_pct"]),
                             x="fine_grade_pct", nbins=25,
                             title="Fine Grade % Distribution",
                             labels={"fine_grade_pct":"Fine Grade %"},
                             color_discrete_sequence=["#4A7C59"])
        med_f = filtered["fine_grade_pct"].median()
        fig3.add_vline(x=med_f, line_dash="dash", line_color="red",
                       annotation_text=f"Median {med_f:.1f}%",
                       annotation_position="top right")
        st.plotly_chart(fig3, use_container_width=True)

    with tab4:
        fig4 = px.histogram(filtered.dropna(subset=["bean_moisture"]),
                             x="bean_moisture", nbins=20,
                             title="Bean Moisture % Distribution",
                             labels={"bean_moisture":"Moisture %"},
                             color_discrete_sequence=["#6B8E6B"])
        med_m = filtered["bean_moisture"].median()
        fig4.add_vline(x=med_m, line_dash="dash", line_color="red",
                       annotation_text=f"Median {med_m:.1f}%",
                       annotation_position="top right")
        fig4.add_vrect(x0=10.5, x1=12.5, fillcolor="green", opacity=0.1,
                       annotation_text="Ideal 10.5–12.5%", annotation_position="top left")
        st.plotly_chart(fig4, use_container_width=True)

    st.markdown("### Grade Summary by Season")
    grade_tbl = (filtered.groupby("season")
                 .agg(fine_kg=("grade_fine","sum"),
                      premium_kg=("grade_premium","sum"),
                      commercial_kg=("grade_commercial","sum"),
                      avg_fine_pct=("fine_grade_pct","mean"),
                      avg_premium_pct=("premium_grade_pct","mean"),
                      avg_commercial_pct=("commercial_grade_pct","mean"))
                 .round(2).reset_index())
    st.dataframe(grade_tbl, use_container_width=True, hide_index=True)

# ═════════════════════════════════════════════════════════════════════════════
# PAGE: CORRELATION ANALYSIS
# ═════════════════════════════════════════════════════════════════════════════
elif page == "🔗 Correlation Analysis":
    st.title("🔗 Correlation Analysis")
    st.markdown("Pearson correlation between agronomic features and yield/quality targets.")

    FEATURE_COLS = [
        "plant_age_months","pre_yield_kg","pruning_interval_months","shade_binary",
        "soil_ph","avg_temp_c","avg_rainfall_mm","avg_humidity_pct","elevation_m",
        "area_size_sqm","plant_count","defect_count","bean_moisture",
        "previous_fine_pct","previous_premium_pct","previous_commercial_pct"
    ]
    TARGET_COLS = ["yield_kg","fine_grade_pct","premium_grade_pct","commercial_grade_pct"]

    corr_df = filtered[[c for c in FEATURE_COLS+TARGET_COLS if c in filtered.columns]]
    corr_df = corr_df.apply(pd.to_numeric, errors="coerce")
    corr_mat = corr_df.corr().round(3)

    tab1, tab2 = st.tabs(["Heatmap", "Feature → Yield Ranking"])

    with tab1:
        fig = px.imshow(corr_mat, text_auto=".2f", aspect="auto",
                        color_continuous_scale="RdYlGn",
                        color_continuous_midpoint=0,
                        title="Full Correlation Matrix")
        fig.update_layout(height=600)
        st.plotly_chart(fig, use_container_width=True)

    with tab2:
        target_sel = st.selectbox("Target variable", TARGET_COLS)
        if target_sel in corr_mat.columns:
            yc = corr_mat[target_sel].drop(TARGET_COLS, errors="ignore").sort_values(key=abs, ascending=True)
            colors = ["#1B5E20" if v > 0 else "#B71C1C" for v in yc.values]
            fig2 = go.Figure(go.Bar(x=yc.values, y=yc.index, orientation="h",
                                    marker_color=colors,
                                    text=[f"{v:.3f}" for v in yc.values],
                                    textposition="outside"))
            fig2.add_vline(x=0, line_color="black", line_width=1)
            fig2.update_layout(title=f"Feature Correlation with {target_sel}",
                                xaxis_title="Pearson r", yaxis_title="",
                                height=500)
            st.plotly_chart(fig2, use_container_width=True)

# ═════════════════════════════════════════════════════════════════════════════
# PAGE: ML MODELS
# ═════════════════════════════════════════════════════════════════════════════
elif page == "🤖 ML Models":
    st.title("🤖 ML Models")
    st.markdown("Yield regression (GBR, RF, Ridge) and grade proportion models (GBR) with cross-validated metrics.")

    result = train_models(filtered)
    if result is None or result[0] is None:
        st.warning("⚠️ Not enough ML-ready rows to train models. Check filters — ensure at least 10 complete rows with all features.")
        st.stop()

    results, grade_models, grade_metrics, imp, best_name, ml_clean = result

    tab1, tab2, tab3, tab4 = st.tabs(["Yield Model Comparison", "Actual vs Predicted", "Feature Importance", "Grade Models"])

    with tab1:
        metric_rows = [{"Model":n,"MAE (kg)":r["MAE"],"RMSE (kg)":r["RMSE"],
                         "R²":r["R2"],"CV R²":r["CV_R2"]} for n,r in results.items()]
        df_m = pd.DataFrame(metric_rows)
        st.dataframe(df_m, use_container_width=True, hide_index=True)
        fig = px.bar(df_m, x="Model", y="R²",
                     title="Yield Model R² Comparison",
                     color="Model", text_auto=".3f",
                     color_discrete_sequence=["#4A7C59","#6B8E6B","#B5CFB7"])
        fig.update_traces(textposition="outside")
        st.plotly_chart(fig, use_container_width=True)

    with tab2:
        m_sel = st.selectbox("Select model", list(results.keys()), index=list(results.keys()).index(best_name))
        r = results[m_sel]
        fig2 = px.scatter(x=r["y_test"], y=r["y_pred"],
                          labels={"x":"Actual Yield (kg)","y":"Predicted Yield (kg)"},
                          title=f"{m_sel} — Actual vs Predicted | R²={r['R2']:.3f} MAE={r['MAE']:.1f} kg",
                          opacity=0.7,
                          color_discrete_sequence=["#4A7C59"])
        lim = [min(r["y_test"].min(), r["y_pred"].min())-5,
               max(r["y_test"].max(), r["y_pred"].max())+5]
        fig2.add_trace(go.Scatter(x=lim, y=lim, mode="lines",
                                  line=dict(color="red", dash="dash"),
                                  name="Perfect Fit"))
        st.plotly_chart(fig2, use_container_width=True)

    with tab3:
        top_n = st.slider("Top N features", 5, len(imp), min(15,len(imp)))
        top_imp = imp.head(top_n)
        fig3 = px.bar(x=top_imp.values, y=top_imp.index,
                      orientation="h",
                      title=f"GBR Feature Importance (Top {top_n})",
                      labels={"x":"Importance Score","y":"Feature"},
                      color=top_imp.values, color_continuous_scale="Greens",
                      text_auto=".4f")
        fig3.update_layout(yaxis=dict(autorange="reversed"), showlegend=False, height=500)
        st.plotly_chart(fig3, use_container_width=True)

    with tab4:
        g_rows = [{"Grade Target":k.replace("_grade_pct","").replace("_pct","").title(),
                   "MAE (%)":v["MAE"],"R²":v["R2"],"CV R²":v["CV_R2"]}
                  for k,v in grade_metrics.items()]
        st.dataframe(pd.DataFrame(g_rows), use_container_width=True, hide_index=True)

        grade_sel = st.selectbox("Grade target", list(grade_metrics.keys()))
        gm = grade_metrics[grade_sel]
        fig4 = px.scatter(x=gm["y_test"], y=gm["y_pred"],
                          labels={"x":f"Actual {grade_sel}","y":f"Predicted {grade_sel}"},
                          title=f"{grade_sel} — Actual vs Predicted | R²={gm['R2']:.3f}",
                          opacity=0.7, color_discrete_sequence=["#66BB6A"])
        lim2 = [min(gm["y_test"].min(), gm["y_pred"].min())-1,
                max(gm["y_test"].max(), gm["y_pred"].max())+1]
        fig4.add_trace(go.Scatter(x=lim2, y=lim2, mode="lines",
                                   line=dict(color="red", dash="dash"), name="Perfect Fit"))
        st.plotly_chart(fig4, use_container_width=True)

        g_imp = pd.Series(grade_models[grade_sel].feature_importances_, index=ML_FEATURES).sort_values(ascending=False)
        fig5 = px.bar(x=g_imp.head(10).values, y=g_imp.head(10).index,
                      orientation="h",
                      title=f"Feature Importance — {grade_sel}",
                      labels={"x":"Importance","y":"Feature"},
                      color=g_imp.head(10).values, color_continuous_scale="Greens",
                      text_auto=".4f")
        fig5.update_layout(yaxis=dict(autorange="reversed"), showlegend=False, height=400)
        st.plotly_chart(fig5, use_container_width=True)

# ═════════════════════════════════════════════════════════════════════════════
# PAGE: YIELD DROP DETECTION
# ═════════════════════════════════════════════════════════════════════════════
elif page == "⚠️ Yield Drop Detection":
    st.title("⚠️ Yield Drop Detection")
    st.markdown("Season-over-season comparison flags clusters with critical or moderate yield decline.")

    drop_df = filtered.dropna(subset=["yield_kg","pre_yield_kg"]).copy()
    if drop_df.empty:
        st.warning("No rows with both current and previous yield data available.")
        st.stop()

    tab1, tab2, tab3, tab4 = st.tabs(["Status Overview", "Δ% Distribution", "Scatter: Prev vs Current", "Critical Clusters"])

    with tab1:
        sc = drop_df["yield_status"].value_counts().reset_index()
        sc.columns = ["Status","Count"]
        sc["Color"] = sc["Status"].astype(str).map(STATUS_COLORS).fillna("grey")
        fig = go.Figure(go.Bar(x=sc["Status"], y=sc["Count"],
                               marker_color=sc["Color"],
                               text=sc["Count"], textposition="outside"))
        fig.update_layout(title="Cluster-Season Yield Status", xaxis_title="Status", yaxis_title="Count")
        st.plotly_chart(fig, use_container_width=True)

        col1, col2, col3, col4 = st.columns(4)
        for col, status in [(col1,"Critical Drop (>20%)"),(col2,"Moderate Drop (5-20%)"),
                            (col3,"Stable (±5%)"),(col4,"Improvement (>5%)")]:
            cnt = (drop_df["yield_status"]==status).sum()
            col.metric(status, cnt)

    with tab2:
        fig2 = px.histogram(drop_df.dropna(subset=["yield_delta_pct"]),
                             x="yield_delta_pct", nbins=30,
                             title="Yield Δ% Distribution (Current vs Previous Season)",
                             labels={"yield_delta_pct":"Δ% Yield"},
                             color_discrete_sequence=["#6B8E6B"])
        fig2.add_vline(x=0, line_dash="dash", line_color="red", annotation_text="No change")
        mean_d = drop_df["yield_delta_pct"].mean()
        fig2.add_vline(x=mean_d, line_dash="dot", line_color="orange",
                       annotation_text=f"Mean {mean_d:.1f}%")
        st.plotly_chart(fig2, use_container_width=True)

    with tab3:
        hover_cols = [c for c in ["cluster_name","farm_name","season","yield_status"] if c in drop_df.columns]
        fig3 = px.scatter(drop_df.dropna(subset=["pre_yield_kg","yield_kg"]),
                          x="pre_yield_kg", y="yield_kg",
                          color="yield_status",
                          color_discrete_map=STATUS_COLORS,
                          hover_data=hover_cols,
                          title="Previous vs Current Yield",
                          labels={"pre_yield_kg":"Previous Yield (kg)","yield_kg":"Current Yield (kg)"},
                          opacity=0.75)
        lim = max(drop_df[["pre_yield_kg","yield_kg"]].max()) * 1.05
        fig3.add_trace(go.Scatter(x=[0,lim],y=[0,lim],mode="lines",
                                   line=dict(color="black",dash="dash"),
                                   showlegend=False, name="No change"))
        st.plotly_chart(fig3, use_container_width=True)

    with tab4:
        critical = drop_df[drop_df["yield_status"]=="Critical Drop (>20%)"].copy()
        if critical.empty:
            st.success("✅ No critical yield drops detected in the selected filters.")
        else:
            st.warning(f"⚠️ {len(critical)} critical drop records found.")
            show_cols = [c for c in ["cluster_name","farm_name","season","yield_kg","pre_yield_kg",
                                      "yield_delta_pct","avg_temp_c","soil_ph",
                                      "pruning_interval_months","fertilizer_frequency"] if c in critical.columns]
            st.dataframe(critical[show_cols].sort_values("yield_delta_pct").round(2),
                         use_container_width=True, hide_index=True)

    # Stacked by season
    st.markdown("### Yield Status by Season")
    if "yield_status" in drop_df.columns:
        ss = (drop_df.groupby(["season","yield_status"], observed=False)
              .size().reset_index(name="count").sort_values("season"))
        fig4 = px.bar(ss, x="season", y="count", color="yield_status",
                      color_discrete_map=STATUS_COLORS,
                      title="Yield Status Distribution per Season",
                      labels={"count":"Count","season":"Season","yield_status":"Status"})
        fig4.update_layout(barmode="stack")
        st.plotly_chart(fig4, use_container_width=True)

# ═════════════════════════════════════════════════════════════════════════════
# PAGE: HARVEST DATE ESTIMATOR
# ═════════════════════════════════════════════════════════════════════════════
elif page == "🌸 Harvest Date Estimator":
    st.title("🌸 Harvest Date Estimator")
    st.markdown("Estimates harvest date from observed flowering date using historical flowering→harvest intervals.")

    int_df = filtered.dropna(subset=["flowering_to_harvest_days"]).copy()
    int_df = int_df[int_df["flowering_to_harvest_days"].between(30, 450)]

    tab1, tab2, tab3 = st.tabs(["Interval Distribution", "Interval vs Climate", "📅 Estimate Date"])

    with tab1:
        if int_df.empty:
            st.info("No flowering-to-harvest interval data available.")
        else:
            med_i = int_df["flowering_to_harvest_days"].median()
            fig = px.histogram(int_df, x="flowering_to_harvest_days", nbins=25,
                               title="Flowering → Harvest Interval (days)",
                               labels={"flowering_to_harvest_days":"Days"},
                               color_discrete_sequence=["#4A7C59"])
            fig.add_vline(x=med_i, line_dash="dash", line_color="red",
                          annotation_text=f"Median {med_i:.0f} d ({med_i/30.44:.1f} mo)")
            fig.add_vrect(x0=150, x1=200, fillcolor="orange", opacity=0.1, annotation_text="5–7 mo")
            fig.add_vrect(x0=200, x1=270, fillcolor="blue", opacity=0.07, annotation_text="7–9 mo")
            st.plotly_chart(fig, use_container_width=True)
            st.metric("Median interval", f"{med_i:.0f} days ({med_i/30.44:.1f} months)")

    with tab2:
        if int_df.empty or "avg_temp_c" not in int_df.columns:
            st.info("Climate data not available for selected filters.")
        else:
            color_col = st.selectbox("Color by", ["elevation_m","avg_rainfall_mm","soil_ph"])
            fig2 = px.scatter(int_df.dropna(subset=[color_col,"avg_temp_c"]),
                              x="avg_temp_c", y="flowering_to_harvest_days",
                              color=color_col, color_continuous_scale="Greens",
                              hover_data=[c for c in ["cluster_name","season"] if c in int_df.columns],
                              title="Flowering→Harvest Interval vs Temperature",
                              labels={"avg_temp_c":"Avg Temp (°C)",
                                      "flowering_to_harvest_days":"Interval (days)"})
            st.plotly_chart(fig2, use_container_width=True)

            fig3 = px.box(int_df, x="season", y="flowering_to_harvest_days",
                          title="Interval Distribution by Season",
                          color="season",
                          labels={"flowering_to_harvest_days":"Days"})
            fig3.update_layout(showlegend=False)
            st.plotly_chart(fig3, use_container_width=True)

    with tab3:
        st.subheader("📅 Estimate Your Harvest Date")
        st.caption("Uses median observed interval adjusted by climate inputs.")
        col1, col2 = st.columns(2)
        with col1:
            f_date = st.date_input("Flowering date", value=datetime(2025, 3, 1))
            avg_temp = st.slider("Avg Temperature (°C)", 13.0, 30.0, 22.0, 0.1)
            avg_rain = st.slider("Avg Rainfall (mm/month)", 50.0, 400.0, 200.0, 5.0)
        with col2:
            avg_humid = st.slider("Avg Humidity (%)", 50.0, 100.0, 80.0, 1.0)
            elevation = st.slider("Elevation (m)", 200, 1500, 800, 10)
            shade = st.checkbox("Shade trees present", value=True)

        if not int_df.empty:
            base = int_df["flowering_to_harvest_days"].median()
        else:
            base = 210

        # Simple rule adjustments
        adj = 0
        if avg_temp > 26:  adj += (avg_temp - 26) * 3
        if avg_temp < 18:  adj -= (18 - avg_temp) * 2
        if elevation > 1000: adj += (elevation - 1000) * 0.05
        if shade: adj -= 7
        estimated_days = int(base + adj)
        est_date = pd.to_datetime(f_date) + pd.Timedelta(days=estimated_days)

        st.success(f"🗓️ Estimated harvest date: **{est_date.strftime('%B %d, %Y')}**  ({estimated_days} days after flowering)")
        col_a, col_b, col_c = st.columns(3)
        col_a.metric("Base interval (median)", f"{base:.0f} days")
        col_b.metric("Adjustment", f"{adj:+.0f} days")
        col_c.metric("Estimated interval", f"{estimated_days} days")

# ═════════════════════════════════════════════════════════════════════════════
# PAGE: RECOMMENDATIONS
# ═════════════════════════════════════════════════════════════════════════════
elif page == "💡 Recommendations":
    st.title("💡 Agronomic Recommendations")
    st.markdown("Rule-based engine aligned to Robusta ideal ranges. Flags deviations per cluster-season.")

    latest_s = st.selectbox("Season", season_order[::-1])
    current = filtered[filtered["season"] == latest_s].copy()

    if current.empty:
        st.warning("No data for selected season.")
        st.stop()

    all_recs = []
    for _, row in current.iterrows():
        recs = get_recommendations(row)
        for r in recs:
            r["cluster_name"] = row.get("cluster_name","")
            r["farm_name"]    = row.get("farm_name","")
            r["season"]       = row.get("season","")
            r["yield_kg"]     = row.get("yield_kg")
            all_recs.append(r)

    if not all_recs:
        st.success("✅ All clusters within Robusta ideal ranges for this season.")
        st.stop()

    rec_df = pd.DataFrame(all_recs)
    PRIORITY_RANK = {"High":0,"Medium":1,"Low":2}
    rec_df["p_rank"] = rec_df["priority"].map(PRIORITY_RANK)
    rec_df = rec_df.sort_values(["p_rank","farm_name","cluster_name"]).reset_index(drop=True)
    rec_df.drop(columns=["p_rank"], inplace=True)

    PRIORITY_COLORS = {"High":"🔴","Medium":"🟠","Low":"🟢"}

    tab1, tab2, tab3 = st.tabs(["Summary Charts", "Full Recommendations", "Ideal Ranges"])

    with tab1:
        c1, c2, c3 = st.columns(3)
        c1.metric("🔴 High Priority",   (rec_df["priority"]=="High").sum())
        c2.metric("🟠 Medium Priority", (rec_df["priority"]=="Medium").sum())
        c3.metric("🟢 Low Priority",    (rec_df["priority"]=="Low").sum())

        rec_ct = rec_df.groupby(["factor","priority"]).size().reset_index(name="count")
        fig = px.bar(rec_ct, x="factor", y="count", color="priority",
                     color_discrete_map={"High":"#d62728","Medium":"#ff7f0e","Low":"#2ca02c"},
                     title=f"Recommendations by Factor — {latest_s}",
                     labels={"factor":"Factor","count":"Clusters Affected","priority":"Priority"})
        fig.update_layout(xaxis_tickangle=-30)
        st.plotly_chart(fig, use_container_width=True)

        p_ct = rec_df["priority"].value_counts().reset_index()
        p_ct.columns = ["Priority","Count"]
        fig2 = px.pie(p_ct, names="Priority", values="Count",
                      color="Priority",
                      color_discrete_map={"High":"#d62728","Medium":"#ff7f0e","Low":"#2ca02c"},
                      title="Priority Distribution")
        st.plotly_chart(fig2, use_container_width=True)

    with tab2:
        priority_filter = st.multiselect("Filter by priority", ["High","Medium","Low"],
                                          default=["High","Medium","Low"])
        show = rec_df[rec_df["priority"].isin(priority_filter)].copy()
        for _, row in show.iterrows():
            icon = PRIORITY_COLORS.get(row["priority"],"⚪")
            with st.expander(f"{icon} [{row['priority']}] {row.get('farm_name','')} — {row.get('cluster_name','')} | {row['factor']} = {row['value']} (ideal: {row['ideal']})"):
                st.write(row["recommendation"])

    with tab3:
        ideal_data = [{"Factor":k, "Min":v[0], "Max":v[1]} for k,v in ROBUSTA_IDEALS.items()]
        st.table(pd.DataFrame(ideal_data))

        # Radar chart for a selected cluster
        if "cluster_name" in current.columns:
            cluster_sel = st.selectbox("View cluster radar", current["cluster_name"].dropna().unique())
            row = current[current["cluster_name"]==cluster_sel].iloc[0]
            radar_features = ["soil_ph","avg_temp_c","avg_humidity_pct",
                               "avg_rainfall_mm","elevation_m","pruning_interval_months"]
            radar_features = [f for f in radar_features if f in row.index and pd.notna(row[f])]
            if radar_features:
                vals = [float(row[f]) for f in radar_features]
                lo_n = [ROBUSTA_IDEALS.get(f,(0,0))[0] for f in radar_features]
                hi_n = [ROBUSTA_IDEALS.get(f,(1,1))[1] for f in radar_features]
                # Normalize 0-1
                norm_vals = [(v-l)/(h-l) if h!=l else 0.5 for v,l,h in zip(vals,lo_n,hi_n)]
                norm_ideal = [0.5]*len(radar_features)
                fig_r = go.Figure()
                fig_r.add_trace(go.Scatterpolar(r=norm_ideal+[norm_ideal[0]],
                                                 theta=radar_features+[radar_features[0]],
                                                 fill="toself", name="Ideal (midpoint)",
                                                 line_color="#2ca02c", opacity=0.4))
                fig_r.add_trace(go.Scatterpolar(r=norm_vals+[norm_vals[0]],
                                                 theta=radar_features+[radar_features[0]],
                                                 fill="toself", name=cluster_sel,
                                                 line_color="#4A7C59"))
                fig_r.update_layout(polar=dict(radialaxis=dict(visible=True,range=[0,1.5])),
                                     title=f"Cluster vs Ideal Ranges — {cluster_sel}",
                                     showlegend=True)
                st.plotly_chart(fig_r, use_container_width=True)

# ═════════════════════════════════════════════════════════════════════════════
# PAGE: RAW DATA
# ═════════════════════════════════════════════════════════════════════════════
elif page == "🗃️ Raw Data":
    st.title("🗃️ Raw Data Explorer")
    st.caption("Filtered flat analytics table — all pipeline-derived columns.")

    search = st.text_input("🔍 Search cluster / farm name")
    show_df = filtered.copy()
    if search:
        mask = show_df.apply(lambda col: col.astype(str).str.contains(search, case=False, na=False)).any(axis=1)
        show_df = show_df[mask]

    cols_to_show = st.multiselect(
        "Select columns to display",
        list(show_df.columns),
        default=[c for c in ["cluster_name","farm_name","season","yield_kg",
                              "fine_grade_pct","premium_grade_pct","commercial_grade_pct",
                              "yield_delta_pct","yield_status","avg_temp_c","soil_ph",
                              "avg_rainfall_mm","avg_humidity_pct","elevation_m",
                              "fertilizer_type","fertilizer_frequency"] if c in show_df.columns]
    )
    st.dataframe(show_df[cols_to_show].reset_index(drop=True), use_container_width=True)

    @st.cache_data
    def to_csv(df):
        return df.to_csv(index=False).encode("utf-8")

    st.download_button("⬇️ Download filtered table as CSV",
                        data=to_csv(show_df[cols_to_show]),
                        file_name="coffee_analytics_filtered.csv",
                        mime="text/csv")