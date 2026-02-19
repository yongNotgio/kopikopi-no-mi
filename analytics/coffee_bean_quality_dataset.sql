-- ================================================
-- COFFEE BEAN QUALITY GRADING DATASET
-- Generated realistic data for Robusta coffee
-- Western Visayas + Negros Occidental
-- ================================================

-- ENUMS
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'plant_stage' AND n.nspname = 'public'
  ) THEN
    CREATE TYPE public.plant_stage AS ENUM (
      'seed-sapling',
      'sapling',
      'tree'
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'fertilizer_kind' AND n.nspname = 'public'
  ) THEN
    CREATE TYPE public.fertilizer_kind AS ENUM (
      'organic',
      'non-organic',
      'both',
      'none'
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'pesticide_kind' AND n.nspname = 'public'
  ) THEN
    CREATE TYPE public.pesticide_kind AS ENUM (
      'organic',
      'non-organic',
      'both',
      'none'
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'fertilizer_freq' AND n.nspname = 'public'
  ) THEN
    CREATE TYPE public.fertilizer_freq AS ENUM (
      'never',
      'rarely',
      'sometimes',
      'often'
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE t.typname = 'pesticide_freq' AND n.nspname = 'public'
  ) THEN
    CREATE TYPE public.pesticide_freq AS ENUM (
      'never',
      'rarely',
      'sometimes',
      'often'
    );
  END IF;
END$$;

-- TABLES
CREATE TABLE IF NOT EXISTS users (id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), username varchar(255) UNIQUE NOT NULL, email varchar(255) UNIQUE NOT NULL, password_hash varchar(255) NOT NULL, first_name varchar(255) NOT NULL, last_name varchar(255) NOT NULL, middle_initial varchar(10), contact_number varchar(255) NOT NULL, age integer NOT NULL CHECK (age >= 18 AND age <= 120), municipality varchar(255) NOT NULL, province varchar(255) NOT NULL, role varchar(255), created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now());

CREATE TABLE IF NOT EXISTS farms (id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), user_id uuid UNIQUE NOT NULL REFERENCES users(id), farm_name varchar(255), farm_area numeric, elevation_m numeric, overall_tree_count integer, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now());

CREATE TABLE IF NOT EXISTS clusters (id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), farm_id uuid NOT NULL REFERENCES farms(id), cluster_name varchar(255) NOT NULL, area_size_sqm numeric NOT NULL, plant_count integer NOT NULL, variety varchar(255), plant_stage plant_stage NOT NULL DEFAULT 'seed-sapling', created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now());

CREATE TABLE IF NOT EXISTS cluster_stage_data (id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), cluster_id uuid NOT NULL REFERENCES clusters(id), season varchar(50) NOT NULL, date_planted date, plant_age_months integer, number_of_plants integer, fertilizer_type fertilizer_kind, fertilizer_frequency fertilizer_freq, pesticide_type pesticide_kind, pesticide_frequency pesticide_freq, last_pruned_date date, previous_pruned_date date, pruning_interval_months integer, shade_tree_present boolean, shade_tree_species varchar(255), soil_ph numeric, avg_temp_c numeric, avg_rainfall_mm numeric, avg_humidity_pct numeric, actual_flowering_date date, estimated_flowering_date date, estimated_harvest_date date, actual_harvest_date date, pre_last_harvest_date date, pre_total_trees integer, pre_yield_kg numeric, pre_grade_fine numeric, pre_grade_premium numeric, pre_grade_commercial numeric, previous_fine_pct numeric, previous_premium_pct numeric, previous_commercial_pct numeric, defect_count integer, bean_moisture numeric, bean_screen_size varchar(255), predicted_yield numeric, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), CONSTRAINT uq_cluster_season UNIQUE (cluster_id, season));

CREATE TABLE IF NOT EXISTS harvest_records (id uuid PRIMARY KEY DEFAULT uuid_generate_v4(), cluster_id uuid NOT NULL REFERENCES clusters(id), season varchar(255), actual_harvest_date date, yield_kg numeric, grade_fine numeric, grade_premium numeric, grade_commercial numeric, fine_pct numeric GENERATED ALWAYS AS (grade_fine / NULLIF(yield_kg, 0) * 100) STORED, premium_pct numeric GENERATED ALWAYS AS (grade_premium / NULLIF(yield_kg, 0) * 100) STORED, commercial_pct numeric GENERATED ALWAYS AS (grade_commercial / NULLIF(yield_kg, 0) * 100) STORED, notes text, recorded_at timestamptz NOT NULL DEFAULT now());

-- USERS, FARMS, CLUSTERS
INSERT INTO users (id,username,email,password_hash,first_name,last_name,middle_initial,contact_number,age,municipality,province,role,created_at,updated_at) VALUES
('2d2f4bf8-38d8-45cd-a31e-7abe6ef54d8d','reyesj1','reyesj1@farmmail.ph','2f0fcd29cf9c179b59a2adb397739c6d010404d343badf0a1da42f8d0d6d3e3b','Juan','Reyes','A','09786579303',35,'Murcia','Negros Occidental','farmer',NOW(),NOW()),
('1d9375c4-2845-4007-9cdc-fe0369408456','cruzm2','cruzm2@farmmail.ph','32061173bad48e5bff95a6e242c7df4a160f6a897d739297ab87a08e8c20b970','Maria','Cruz','B','09126855092',45,'Himamaylan','Negros Occidental','farmer',NOW(),NOW()),
('71eeea2b-3121-45c5-8f79-167bb2778d84','santosp3','santosp3@farmmail.ph','efff6c06ca1d534d183f8ba930edb8f5367a288dd4cdd4989b6046b4ce66366d','Pedro','Santos','C','09362950628',42,'Silay','Negros Occidental','farmer',NOW(),NOW()),
('bc28865e-6ba8-4fe4-9d89-d4a235259104','bautistar4','bautistar4@farmmail.ph','4c70b2a6813def0fd7bf97507214900ef71af72cf10b68970d2b1bfabe3e1851','Rosa','Bautista','D','09249827706',34,'La Castellana','Negros Occidental','farmer',NOW(),NOW()),
('6b9db333-d8c9-45bc-a332-c5e63822a1e2','villanuevaa5','villanuevaa5@farmmail.ph','65451fbcf6b698664a057f39e5e170e4a14cf9c1edf15605575205571ee11711','Andres','Villanueva','E','09826600539',62,'Isabela','Negros Occidental','farmer',NOW(),NOW()),
('deb1b65c-00fa-4e37-8200-b570e0fd9fd7','floresl6','floresl6@farmmail.ph','aee83abeeb17c43eaba7556195f56e7ca96d8e2443230113feda27273ed35fce','Luz','Flores','F','09193349856',55,'Binalbagan','Negros Occidental','farmer',NOW(),NOW()),
('08bc5c64-8e7d-4cb4-bb2d-c9f4e9a0cee7','garciar7','garciar7@farmmail.ph','fff264dbea030ce407cd79a6a021521dcaa5d5737004bdd1e429665edf0a0ee9','Ricardo','Garcia','G','09134126396',29,'Kabankalan','Negros Occidental','farmer',NOW(),NOW()),
('fffd63fc-3162-48e0-a741-232f6614c2c6','ramosc8','ramosc8@farmmail.ph','ca8ad56a507f05617d33e546a9e1ff5b4c36559890bdcf4d3a4843526c94dc20','Carmen','Ramos','H','09200604502',41,'Ilog','Negros Occidental','farmer',NOW(),NOW()),
('d7047127-9584-42b4-a82a-d984b98368ec','mendozae9','mendozae9@farmmail.ph','2a0d21f9b42b0d8890f2b431287744c725a0967bccac085ca04436aac2632edf','Eduardo','Mendoza','I','09349817734',60,'Hinigaran','Negros Occidental','farmer',NOW(),NOW()),
('4b88cc83-f0c1-45e0-bf87-a049f5478b1d','torrest10','torrest10@farmmail.ph','1c2453f957c3c339bac1258f9429166d69a498eb7af8c74966589b5b8db64daf','Teresita','Torres','J','09746412689',29,'Valladolid','Negros Occidental','farmer',NOW(),NOW()),
('17187552-ad71-4851-871e-e8f6a2655e3c','castillof11','castillof11@farmmail.ph','21aefd5f75c2f3073802410e4dd16db4f4af563f84460f79d00ea0bfa9f8c8ff','Fernando','Castillo','K','09702632297',40,'Calinog','Iloilo','farmer',NOW(),NOW()),
('8591412a-740b-4ff0-8606-d2ef11a504f0','delacruzg12','delacruzg12@farmmail.ph','8ec16494ca39d15fe63f3c4d41baea5513aeebb8b002536c84d1e6a3f70e94a4','Gloria','Dela Cruz','L','09868820204',62,'Igbaras','Iloilo','farmer',NOW(),NOW()),
('b981bab6-21a1-4c8a-85e4-7b0b822be20e','aquinoe13','aquinoe13@farmmail.ph','707863ba6d55d860483f2ef0492e06d036b1455c0a0fc19eca7770ad9891646e','Ernesto','Aquino','M','09550455977',42,'Lambunao','Iloilo','farmer',NOW(),NOW()),
('6123c5bc-913f-4576-b546-3f69bb7eefa3','limj14','limj14@farmmail.ph','4069aa8678f4b12b11b7fa7a9d96c42f569271c56c766b41bbf4927ba94410e2','Josefa','Lim','N','09582334538',45,'Sibalom','Antique','farmer',NOW(),NOW()),
('1bc1d70d-2b4d-4aef-982e-1a3974649b7f','ocampor15','ocampor15@farmmail.ph','7057da532413e3e8b4bddf62320945ba95d1b56f6eef6f726a7bf9f4f5cfc32a','Rodrigo','Ocampo','O','09969119330',28,'Barotac Viejo','Antique','farmer',NOW(),NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO farms (id,user_id,farm_name,farm_area,elevation_m,overall_tree_count,created_at,updated_at) VALUES
('3cf70483-6172-4ab1-81f1-9833847264e3','2d2f4bf8-38d8-45cd-a31e-7abe6ef54d8d','Kape ni Reyes Farm',7.45,695.8,3660,NOW(),NOW()),
('78e4acd8-66eb-403a-b7b4-1a09ec42f040','1d9375c4-2845-4007-9cdc-fe0369408456','Bulod Cruz Coffee',3.36,729.2,1764,NOW(),NOW()),
('0070bb92-63fe-410e-ab84-922dccdc4df1','71eeea2b-3121-45c5-8f79-167bb2778d84','Lupain Santos Farm',1.87,828.0,906,NOW(),NOW()),
('6642a6f0-9b5b-4b2f-80aa-5db50c7276c3','bc28865e-6ba8-4fe4-9d89-d4a235259104','Bukid Bautista Estate',3.92,758.7,1777,NOW(),NOW()),
('dd2a4f5f-77c5-4733-9c68-b51d3e0f3761','6b9db333-d8c9-45bc-a332-c5e63822a1e2','Halaman Villanueva Garden',4.91,674.9,2657,NOW(),NOW()),
('37416adc-b16a-473e-96cf-3ed860604d38','deb1b65c-00fa-4e37-8200-b570e0fd9fd7','Sinag Flores Coffee Farm',1.67,775.9,854,NOW(),NOW()),
('01710642-2b0a-41bf-ac21-72f4175da1bc','08bc5c64-8e7d-4cb4-bb2d-c9f4e9a0cee7','Tagaytay Garcia Farm',8.53,817.0,3994,NOW(),NOW()),
('bce76718-81b9-4a89-8c91-df239ce7e32e','fffd63fc-3162-48e0-a741-232f6614c2c6','Pag-asa Ramos Coffee',1.59,996.8,836,NOW(),NOW()),
('d1e22ec0-a6bf-4f55-9b0d-8931f518363a','d7047127-9584-42b4-a82a-d984b98368ec','Dagdag Mendoza Estate',9.37,1113.2,5018,NOW(),NOW()),
('7f750c82-8426-4ef1-8f5e-3d3d7f5884f8','4b88cc83-f0c1-45e0-bf87-a049f5478b1d','Yaman Torres Farm',4.23,872.0,2251,NOW(),NOW()),
('fe5a5b46-c51b-43d1-b51a-f40b9185cd3d','17187552-ad71-4851-871e-e8f6a2655e3c','Bukal Castillo Coffee',2.38,813.2,1228,NOW(),NOW()),
('dfdbdee3-cbd5-44a1-8200-38f9d3fb4708','8591412a-740b-4ff0-8606-d2ef11a504f0','Tanaw Cruz Farm',6.97,1010.1,3179,NOW(),NOW()),
('acf3cec6-1965-4a13-bbf4-6997d9947254','b981bab6-21a1-4c8a-85e4-7b0b822be20e','Likha Aquino Garden',6.4,920.5,3030,NOW(),NOW()),
('cb9e3c77-5f23-45f2-807e-a99b72b60f23','6123c5bc-913f-4576-b546-3f69bb7eefa3','Siwang Lim Estate',4.93,762.0,2669,NOW(),NOW()),
('a972156d-3261-4d35-b219-6b13193e9bbf','1bc1d70d-2b4d-4aef-982e-1a3974649b7f','Ulap Ocampo Coffee',6.85,731.8,3298,NOW(),NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO clusters (id,farm_id,cluster_name,area_size_sqm,plant_count,variety,plant_stage,created_at,updated_at) VALUES
('887a9498-d0ad-47de-80e4-754487e94ace','3cf70483-6172-4ab1-81f1-9833847264e3','Cluster A',978.7,51,'Robusta','seed-sapling',NOW(),NOW()),
('ba3e9298-71fc-4632-ae12-884751d4d6d7','3cf70483-6172-4ab1-81f1-9833847264e3','Cluster B',1100.0,49,'Robusta','tree',NOW(),NOW()),
('0c3bc855-8f53-40c7-a06c-625bf253f7ae','3cf70483-6172-4ab1-81f1-9833847264e3','Cluster C',2845.1,145,'Robusta','seed-sapling',NOW(),NOW()),
('932e5e93-5ff6-4934-9a52-5bb684843628','3cf70483-6172-4ab1-81f1-9833847264e3','Cluster D',902.9,42,'Robusta','sapling',NOW(),NOW()),
('95011c83-de4a-4da0-a21b-e6ac6a05e966','3cf70483-6172-4ab1-81f1-9833847264e3','Cluster E',2913.4,152,'Robusta','tree',NOW(),NOW()),
('98b02818-83c0-49ac-81e7-14d66df5165f','78e4acd8-66eb-403a-b7b4-1a09ec42f040','Cluster A',1447.9,73,'Robusta','tree',NOW(),NOW()),
('6255ae6a-e4b1-4317-8521-cdca637c10ca','78e4acd8-66eb-403a-b7b4-1a09ec42f040','Cluster B',527.9,28,'Robusta','tree',NOW(),NOW()),
('31dcdda1-7f23-4925-94e0-0d59983ec737','78e4acd8-66eb-403a-b7b4-1a09ec42f040','Cluster C',1963.1,89,'Robusta','tree',NOW(),NOW()),
('f2ee69ce-b8c3-44c3-937f-8024282f34a6','78e4acd8-66eb-403a-b7b4-1a09ec42f040','Cluster D',1947.4,87,'Robusta','seed-sapling',NOW(),NOW()),
('e9fa3a05-8e19-4c64-9f15-8940e4be321d','0070bb92-63fe-410e-ab84-922dccdc4df1','Cluster A',3096.0,165,'Robusta','tree',NOW(),NOW()),
('d9a44d1d-dea9-4c8d-b180-022d7b46b9d1','0070bb92-63fe-410e-ab84-922dccdc4df1','Cluster B',2805.8,155,'Robusta','sapling',NOW(),NOW()),
('aaf5477b-af8a-4a75-af30-f9515ef9a857','0070bb92-63fe-410e-ab84-922dccdc4df1','Cluster C',2873.8,154,'Robusta','sapling',NOW(),NOW()),
('d5b78ba3-f094-4150-8cfb-e79b8e05331a','0070bb92-63fe-410e-ab84-922dccdc4df1','Cluster D',4205.3,213,'Robusta','tree',NOW(),NOW()),
('d854e252-4b42-43a9-95a4-562341d83c82','6642a6f0-9b5b-4b2f-80aa-5db50c7276c3','Cluster A',3343.4,177,'Robusta','tree',NOW(),NOW()),
('22e9c997-c743-4c3d-972c-5b00f71b83bb','6642a6f0-9b5b-4b2f-80aa-5db50c7276c3','Cluster B',4177.9,226,'Robusta','sapling',NOW(),NOW()),
('93ef4210-a5f3-435a-b7b4-cd60cfdf75e7','6642a6f0-9b5b-4b2f-80aa-5db50c7276c3','Cluster C',2449.7,132,'Robusta','seed-sapling',NOW(),NOW()),
('80fdd0ec-9bb0-4ef6-84b8-58c1fc8012d8','dd2a4f5f-77c5-4733-9c68-b51d3e0f3761','Cluster A',1400.9,65,'Robusta','tree',NOW(),NOW()),
('28bbdc75-5746-4aa3-b264-d527dd716759','dd2a4f5f-77c5-4733-9c68-b51d3e0f3761','Cluster B',3286.6,168,'Robusta','seed-sapling',NOW(),NOW()),
('86fa9300-20a7-4346-980e-5cc4a0a83379','dd2a4f5f-77c5-4733-9c68-b51d3e0f3761','Cluster C',3635.2,166,'Robusta','sapling',NOW(),NOW()),
('fea50ed8-b11c-4586-a273-0b58edbee8de','dd2a4f5f-77c5-4733-9c68-b51d3e0f3761','Cluster D',4755.0,245,'Robusta','sapling',NOW(),NOW()),
('589e2f16-9656-4c94-8549-50db17ce2be5','37416adc-b16a-473e-96cf-3ed860604d38','Cluster A',1894.4,100,'Robusta','seed-sapling',NOW(),NOW()),
('d9be44b6-82e3-4fbd-b6e6-db875863b861','37416adc-b16a-473e-96cf-3ed860604d38','Cluster B',4033.8,216,'Robusta','sapling',NOW(),NOW()),
('5074b97e-3c29-49c0-bfa4-034931344665','37416adc-b16a-473e-96cf-3ed860604d38','Cluster C',784.6,43,'Robusta','sapling',NOW(),NOW()),
('82eed5d7-d586-49f2-913f-78e555f7ed13','37416adc-b16a-473e-96cf-3ed860604d38','Cluster D',3587.0,166,'Robusta','sapling',NOW(),NOW()),
('62d7b93f-9ae3-4c18-9a74-3091844c4e33','37416adc-b16a-473e-96cf-3ed860604d38','Cluster E',4304.1,222,'Robusta','seed-sapling',NOW(),NOW()),
('1dd73c5f-8111-403e-abd0-41107e938273','01710642-2b0a-41bf-ac21-72f4175da1bc','Cluster A',1560.5,79,'Robusta','seed-sapling',NOW(),NOW()),
('f0e659d5-af04-4a13-9b66-75d985f34efb','01710642-2b0a-41bf-ac21-72f4175da1bc','Cluster B',3013.7,164,'Robusta','sapling',NOW(),NOW()),
('3ff6da60-1fa3-4113-94cb-b85fb9fbc66a','01710642-2b0a-41bf-ac21-72f4175da1bc','Cluster C',1443.1,80,'Robusta','sapling',NOW(),NOW()),
('0b0bf418-c4a6-4215-9430-a0bd47277df7','bce76718-81b9-4a89-8c91-df239ce7e32e','Cluster A',3749.9,203,'Robusta','seed-sapling',NOW(),NOW()),
('163a16ab-b56f-4662-8401-5efe215a4f23','bce76718-81b9-4a89-8c91-df239ce7e32e','Cluster B',1187.9,61,'Robusta','sapling',NOW(),NOW()),
('6304d717-5d9e-42b6-8c4e-1ddc9b603a09','bce76718-81b9-4a89-8c91-df239ce7e32e','Cluster C',2154.5,109,'Robusta','sapling',NOW(),NOW()),
('de144329-9a84-4ee1-8771-b1ff9e54b714','d1e22ec0-a6bf-4f55-9b0d-8931f518363a','Cluster A',4675.6,253,'Robusta','seed-sapling',NOW(),NOW()),
('6cac8d82-bb3e-47fc-a172-412d77db327b','d1e22ec0-a6bf-4f55-9b0d-8931f518363a','Cluster B',3599.1,187,'Robusta','sapling',NOW(),NOW()),
('258ea41a-b7ef-4ff1-b812-326c1e8b297e','d1e22ec0-a6bf-4f55-9b0d-8931f518363a','Cluster C',1647.3,84,'Robusta','seed-sapling',NOW(),NOW()),
('ca59205f-b5e7-42fb-ab16-ffa5961d6898','d1e22ec0-a6bf-4f55-9b0d-8931f518363a','Cluster D',2369.5,116,'Robusta','tree',NOW(),NOW()),
('dea8cd83-49a4-4dc2-9218-84c02c4f2336','7f750c82-8426-4ef1-8f5e-3d3d7f5884f8','Cluster A',1632.6,81,'Robusta','seed-sapling',NOW(),NOW()),
('4ce4fd5a-374a-4ee3-8019-5043952959ff','7f750c82-8426-4ef1-8f5e-3d3d7f5884f8','Cluster B',4424.3,240,'Robusta','seed-sapling',NOW(),NOW()),
('a12d98ec-7714-4151-bc79-381deea83e33','7f750c82-8426-4ef1-8f5e-3d3d7f5884f8','Cluster C',3247.5,166,'Robusta','seed-sapling',NOW(),NOW()),
('0274bf00-1a00-40e6-a257-59fa64fa9ac2','7f750c82-8426-4ef1-8f5e-3d3d7f5884f8','Cluster D',3778.8,190,'Robusta','tree',NOW(),NOW()),
('9c565b1c-51d3-4cd3-b206-6712f115bf66','7f750c82-8426-4ef1-8f5e-3d3d7f5884f8','Cluster E',2780.5,122,'Robusta','sapling',NOW(),NOW()),
('80d74c12-eba9-42a8-842c-6f289b6eb41d','fe5a5b46-c51b-43d1-b51a-f40b9185cd3d','Cluster A',981.0,47,'Robusta','tree',NOW(),NOW()),
('a7b8fac6-1745-416f-8eed-a4426de4f0b1','fe5a5b46-c51b-43d1-b51a-f40b9185cd3d','Cluster B',3969.1,185,'Robusta','seed-sapling',NOW(),NOW()),
('1caee4c8-5f87-46f0-9aa3-1c1521c87055','fe5a5b46-c51b-43d1-b51a-f40b9185cd3d','Cluster C',2939.6,131,'Robusta','tree',NOW(),NOW()),
('2bc7aab7-2a95-42c5-9c37-29f1d9d15a47','dfdbdee3-cbd5-44a1-8200-38f9d3fb4708','Cluster A',4705.3,236,'Robusta','seed-sapling',NOW(),NOW()),
('48e1cc01-80fc-44ee-94ad-66a8818a587a','dfdbdee3-cbd5-44a1-8200-38f9d3fb4708','Cluster B',3336.9,184,'Robusta','seed-sapling',NOW(),NOW()),
('c74959ef-9dec-4c60-97fb-fa4942d81a9e','dfdbdee3-cbd5-44a1-8200-38f9d3fb4708','Cluster C',2769.0,141,'Robusta','tree',NOW(),NOW()),
('058bcdad-90b0-438c-8016-e16bcaf6a90c','acf3cec6-1965-4a13-bbf4-6997d9947254','Cluster A',3747.6,195,'Robusta','tree',NOW(),NOW()),
('f4314371-80de-47b9-a67e-aed954435440','acf3cec6-1965-4a13-bbf4-6997d9947254','Cluster B',2215.7,115,'Robusta','sapling',NOW(),NOW()),
('50d6a4c3-800d-4b97-bfda-b01d5ac9c0b3','acf3cec6-1965-4a13-bbf4-6997d9947254','Cluster C',4368.3,215,'Robusta','seed-sapling',NOW(),NOW()),
('d0042b09-ec1d-4cf3-a59a-6277b33cba70','acf3cec6-1965-4a13-bbf4-6997d9947254','Cluster D',775.3,34,'Robusta','sapling',NOW(),NOW()),
('afdbcd84-ff38-4fcf-bc2a-b3af53fdfafe','acf3cec6-1965-4a13-bbf4-6997d9947254','Cluster E',3030.3,133,'Robusta','tree',NOW(),NOW()),
('ee1c8684-863d-4bc2-8a76-56639743cfbf','cb9e3c77-5f23-45f2-807e-a99b72b60f23','Cluster A',1484.4,81,'Robusta','tree',NOW(),NOW()),
('8f0c2ff0-760a-47d2-a144-3014c6031747','cb9e3c77-5f23-45f2-807e-a99b72b60f23','Cluster B',804.7,37,'Robusta','tree',NOW(),NOW()),
('835061c7-e763-4f15-8110-f6ea82c21ce0','cb9e3c77-5f23-45f2-807e-a99b72b60f23','Cluster C',1421.2,64,'Robusta','tree',NOW(),NOW()),
('123aa3d3-dab1-46a5-9b49-07c3695381db','a972156d-3261-4d35-b219-6b13193e9bbf','Cluster A',2977.7,139,'Robusta','sapling',NOW(),NOW()),
('79f13140-a1e8-42bb-a80f-21dc4cd72ef3','a972156d-3261-4d35-b219-6b13193e9bbf','Cluster B',2250.4,101,'Robusta','tree',NOW(),NOW()),
('a59b4841-8111-4535-a88e-6133736bb737','a972156d-3261-4d35-b219-6b13193e9bbf','Cluster C',2023.5,98,'Robusta','tree',NOW(),NOW()),
('1f1f65dd-f84d-476e-b8cb-b47c34b42eb9','a972156d-3261-4d35-b219-6b13193e9bbf','Cluster D',732.9,37,'Robusta','sapling',NOW(),NOW()),
('89f90985-203f-4aa7-a0b2-e7e5a3ff0ecb','a972156d-3261-4d35-b219-6b13193e9bbf','Cluster E',760.6,40,'Robusta','tree',NOW(),NOW())
ON CONFLICT (id) DO NOTHING;

-- HARVEST RECORDS
INSERT INTO harvest_records (id,cluster_id,season,actual_harvest_date,yield_kg,grade_fine,grade_premium,grade_commercial,notes,recorded_at) VALUES
('739e5956-832a-4b43-a096-f7dd3d027dc4','887a9498-d0ad-47de-80e4-754487e94ace','2021-2022','2022-01-09',12.54,1.08,3.76,7.69,'Season 2021-2022. Yield/tree: 0.25 kg. Climate factor: 1.04. MQ index: 0.40.',NOW()),
('bb738dec-7e15-4bd8-be4f-9acc963c6958','887a9498-d0ad-47de-80e4-754487e94ace','2022-2023','2022-11-08',21.7,1.25,4.3,16.16,'Season 2022-2023. Yield/tree: 0.43 kg. Climate factor: 1.07. MQ index: 0.40.',NOW()),
('1287799f-bd99-4ae2-90b1-950b4ced710e','887a9498-d0ad-47de-80e4-754487e94ace','2023-2024','2023-11-09',10.78,1.3,2.9,6.58,'Season 2023-2024. Yield/tree: 0.21 kg. Climate factor: 1.00. MQ index: 0.40.',NOW()),
('b3d45176-b07e-4cda-9935-9d3a85464cf7','887a9498-d0ad-47de-80e4-754487e94ace','2024-2025','2024-12-01',24.66,3.23,5.25,16.19,'Season 2024-2025. Yield/tree: 0.48 kg. Climate factor: 0.98. MQ index: 0.40.',NOW()),
('85f2da67-79ef-4846-8211-5b6e18f1d09e','ba3e9298-71fc-4632-ae12-884751d4d6d7','2021-2022','2021-10-27',10.78,0.92,2.06,7.79,'Season 2021-2022. Yield/tree: 0.22 kg. Climate factor: 0.95. MQ index: 0.20.',NOW()),
('b486708e-7fb8-4e1d-b7b5-eda684d7afe8','ba3e9298-71fc-4632-ae12-884751d4d6d7','2022-2023','2022-10-25',7.35,0.41,1.81,5.13,'Season 2022-2023. Yield/tree: 0.15 kg. Climate factor: 0.96. MQ index: 0.20.',NOW()),
('3ddc68e0-29f6-4b38-8d0f-e03ef6ce9ef7','ba3e9298-71fc-4632-ae12-884751d4d6d7','2023-2024','2023-11-27',9.42,1.24,2.55,5.63,'Season 2023-2024. Yield/tree: 0.19 kg. Climate factor: 1.14. MQ index: 0.20.',NOW()),
('b8bfe15d-7b3c-470f-9bd4-32b006ce181f','ba3e9298-71fc-4632-ae12-884751d4d6d7','2024-2025','2024-10-18',7.35,0.57,1.64,5.14,'Season 2024-2025. Yield/tree: 0.15 kg. Climate factor: 1.02. MQ index: 0.20.',NOW()),
('d1c1aa4b-29d9-4e35-bd6c-11948014e8eb','0c3bc855-8f53-40c7-a06c-625bf253f7ae','2021-2022','2021-11-04',21.75,2.03,6.83,12.9,'Season 2021-2022. Yield/tree: 0.15 kg. Climate factor: 1.11. MQ index: 0.18.',NOW()),
('59da289a-b624-45fe-a0c6-a3600d022510','0c3bc855-8f53-40c7-a06c-625bf253f7ae','2022-2023','2022-12-26',21.75,3.27,5.97,12.5,'Season 2022-2023. Yield/tree: 0.15 kg. Climate factor: 0.96. MQ index: 0.18.',NOW()),
('518eef21-8ff1-4046-b93c-4a2cb2afa42d','0c3bc855-8f53-40c7-a06c-625bf253f7ae','2023-2024','2024-01-01',21.75,2.04,4.77,14.94,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 1.04. MQ index: 0.18.',NOW()),
('b17d117a-62b8-4577-9bce-233aebfef6ca','0c3bc855-8f53-40c7-a06c-625bf253f7ae','2024-2025','2024-10-12',21.75,2.69,3.95,15.11,'Season 2024-2025. Yield/tree: 0.15 kg. Climate factor: 1.06. MQ index: 0.18.',NOW()),
('904da167-1265-4bc9-bc6c-23b0df8bba74','932e5e93-5ff6-4934-9a52-5bb684843628','2023-2024','2024-01-11',6.3,0.93,1.67,3.71,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 1.09. MQ index: 0.25.',NOW()),
('1f332ba8-ade6-4e55-a029-832e5e3c14ba','932e5e93-5ff6-4934-9a52-5bb684843628','2024-2025','2024-11-10',7.94,1.17,1.97,4.8,'Season 2024-2025. Yield/tree: 0.19 kg. Climate factor: 0.94. MQ index: 0.25.',NOW()),
('19af0a54-e453-45c8-a684-1e6e4dc3f672','95011c83-de4a-4da0-a21b-e6ac6a05e966','2021-2022','2021-12-28',88.85,13.13,24.26,51.46,'Season 2021-2022. Yield/tree: 0.58 kg. Climate factor: 0.89. MQ index: 0.76.',NOW()),
('1ba96058-f728-410d-b373-c19bd581d071','95011c83-de4a-4da0-a21b-e6ac6a05e966','2022-2023','2022-10-16',148.56,19.18,30.69,98.69,'Season 2022-2023. Yield/tree: 0.98 kg. Climate factor: 0.97. MQ index: 0.76.',NOW()),
('7b8f1529-c468-433e-b3cc-1c6a26a71cbd','95011c83-de4a-4da0-a21b-e6ac6a05e966','2023-2024','2023-11-30',63.74,9.11,18.82,35.82,'Season 2023-2024. Yield/tree: 0.42 kg. Climate factor: 1.11. MQ index: 0.76.',NOW()),
('db6c17d8-90e2-4046-9feb-2c244af5ba29','95011c83-de4a-4da0-a21b-e6ac6a05e966','2024-2025','2024-10-09',107.33,18.16,36.33,52.84,'Season 2024-2025. Yield/tree: 0.71 kg. Climate factor: 0.96. MQ index: 0.76.',NOW()),
('9cec3c49-77c0-43de-9fad-8d3132c3cd63','98b02818-83c0-49ac-81e7-14d66df5165f','2021-2022','2021-11-27',21.07,2.61,6.34,12.12,'Season 2021-2022. Yield/tree: 0.29 kg. Climate factor: 1.05. MQ index: 0.25.',NOW()),
('81a2067f-7290-46f0-a051-11dc9713d22a','98b02818-83c0-49ac-81e7-14d66df5165f','2022-2023','2022-11-12',13.66,2.13,4.47,7.06,'Season 2022-2023. Yield/tree: 0.19 kg. Climate factor: 0.88. MQ index: 0.25.',NOW()),
('1c6c0cfc-01aa-4d26-bc03-f78a31c6d25d','98b02818-83c0-49ac-81e7-14d66df5165f','2023-2024','2024-01-01',17.51,1.18,4.8,11.54,'Season 2023-2024. Yield/tree: 0.24 kg. Climate factor: 1.14. MQ index: 0.25.',NOW()),
('2d8887a1-05cf-404b-86d7-2a58515a6e09','98b02818-83c0-49ac-81e7-14d66df5165f','2024-2025','2024-12-14',13.8,1.02,4.91,7.88,'Season 2024-2025. Yield/tree: 0.19 kg. Climate factor: 1.00. MQ index: 0.25.',NOW()),
('bd8704cf-99ef-49e5-9c87-0f2cbe7f05da','6255ae6a-e4b1-4317-8521-cdca637c10ca','2021-2022','2021-11-23',9.73,0.7,2.37,6.66,'Season 2021-2022. Yield/tree: 0.35 kg. Climate factor: 1.13. MQ index: 0.38.',NOW()),
('1a9b0af4-c1a6-4e4e-ac1a-f23d38f4fce4','6255ae6a-e4b1-4317-8521-cdca637c10ca','2022-2023','2022-10-18',9.22,0.62,2.75,5.85,'Season 2022-2023. Yield/tree: 0.33 kg. Climate factor: 0.92. MQ index: 0.38.',NOW()),
('e231d661-3464-41d6-bb95-ed3f15e0683c','6255ae6a-e4b1-4317-8521-cdca637c10ca','2023-2024','2023-11-02',6.0,0.72,2.13,3.15,'Season 2023-2024. Yield/tree: 0.21 kg. Climate factor: 1.14. MQ index: 0.38.',NOW()),
('8b5197ca-68e3-4338-afcd-0873b0090823','6255ae6a-e4b1-4317-8521-cdca637c10ca','2024-2025','2025-01-09',8.46,0.71,2.26,5.49,'Season 2024-2025. Yield/tree: 0.30 kg. Climate factor: 0.93. MQ index: 0.38.',NOW()),
('89621fab-6d33-41c9-be24-89e4d65ce047','31dcdda1-7f23-4925-94e0-0d59983ec737','2021-2022','2021-12-20',47.46,6.55,12.39,28.52,'Season 2021-2022. Yield/tree: 0.53 kg. Climate factor: 1.06. MQ index: 0.68.',NOW()),
('ee0de5a3-fe89-46ca-9cc5-7dfe6a536d09','31dcdda1-7f23-4925-94e0-0d59983ec737','2022-2023','2022-12-24',28.15,1.61,8.03,18.51,'Season 2022-2023. Yield/tree: 0.32 kg. Climate factor: 0.99. MQ index: 0.68.',NOW()),
('cf10cbdb-b3cb-4b36-9839-93f47bc63ff1','31dcdda1-7f23-4925-94e0-0d59983ec737','2023-2024','2023-11-23',48.99,4.76,17.01,27.22,'Season 2023-2024. Yield/tree: 0.55 kg. Climate factor: 0.92. MQ index: 0.68.',NOW()),
('56f982ad-56bf-4344-88e9-446421497387','31dcdda1-7f23-4925-94e0-0d59983ec737','2024-2025','2024-12-20',54.44,5.19,11.76,37.49,'Season 2024-2025. Yield/tree: 0.61 kg. Climate factor: 0.87. MQ index: 0.68.',NOW()),
('3c104883-a0a0-4036-bb12-b43f75f082d1','f2ee69ce-b8c3-44c3-937f-8024282f34a6','2021-2022','2022-01-07',36.58,4.0,7.39,25.19,'Season 2021-2022. Yield/tree: 0.42 kg. Climate factor: 1.02. MQ index: 0.54.',NOW()),
('9fd8fad3-5a4b-4d77-9495-09ff5b6aa018','f2ee69ce-b8c3-44c3-937f-8024282f34a6','2022-2023','2022-12-31',39.24,5.27,11.57,22.4,'Season 2022-2023. Yield/tree: 0.45 kg. Climate factor: 0.98. MQ index: 0.54.',NOW()),
('f93d767c-ae99-42cd-8053-26405a1fcc2f','f2ee69ce-b8c3-44c3-937f-8024282f34a6','2023-2024','2023-11-05',27.34,4.03,6.41,16.9,'Season 2023-2024. Yield/tree: 0.31 kg. Climate factor: 0.88. MQ index: 0.54.',NOW()),
('1465fa12-b796-497d-bbdf-4df259c7c9ab','f2ee69ce-b8c3-44c3-937f-8024282f34a6','2024-2025','2024-10-17',27.15,3.1,9.09,14.97,'Season 2024-2025. Yield/tree: 0.31 kg. Climate factor: 1.01. MQ index: 0.54.',NOW()),
('4dcbbf4b-f798-4c71-8af0-a23de7337f31','e9fa3a05-8e19-4c64-9f15-8940e4be321d','2021-2022','2021-10-16',134.37,9.49,53.21,71.67,'Season 2021-2022. Yield/tree: 0.81 kg. Climate factor: 0.98. MQ index: 0.94.',NOW()),
('8cbf9cce-99ec-4999-a4c9-e215e97f9499','e9fa3a05-8e19-4c64-9f15-8940e4be321d','2022-2023','2022-11-06',224.59,21.47,65.24,137.88,'Season 2022-2023. Yield/tree: 1.36 kg. Climate factor: 1.14. MQ index: 0.94.',NOW()),
('c8dbe2d3-d04b-460b-bc49-6d1b8458987b','e9fa3a05-8e19-4c64-9f15-8940e4be321d','2023-2024','2023-12-09',93.24,4.32,25.73,63.19,'Season 2023-2024. Yield/tree: 0.57 kg. Climate factor: 1.11. MQ index: 0.94.',NOW()),
('4c0f1984-cf50-4e9b-ad0e-31d9b442462a','e9fa3a05-8e19-4c64-9f15-8940e4be321d','2024-2025','2024-12-09',163.85,26.31,51.45,86.09,'Season 2024-2025. Yield/tree: 0.99 kg. Climate factor: 0.94. MQ index: 0.94.',NOW()),
('144dd8fe-d4df-4f43-be08-8ad3d0ef30ba','d9a44d1d-dea9-4c8d-b180-022d7b46b9d1','2023-2024','2024-01-15',80.38,9.64,21.93,48.81,'Season 2023-2024. Yield/tree: 0.52 kg. Climate factor: 0.90. MQ index: 0.49.',NOW()),
('149ae912-81fe-485a-a5b6-ba96afac1e05','d9a44d1d-dea9-4c8d-b180-022d7b46b9d1','2024-2025','2024-10-15',59.66,9.17,16.19,34.3,'Season 2024-2025. Yield/tree: 0.38 kg. Climate factor: 0.94. MQ index: 0.49.',NOW()),
('7d1f2486-8b67-4a5f-8661-3d3151bd9b06','aaf5477b-af8a-4a75-af30-f9515ef9a857','2023-2024','2023-11-11',38.07,4.47,11.04,22.57,'Season 2023-2024. Yield/tree: 0.25 kg. Climate factor: 1.14. MQ index: 0.42.',NOW()),
('05eaf100-cec7-4336-a9b5-45a5bed1f210','aaf5477b-af8a-4a75-af30-f9515ef9a857','2024-2025','2024-10-18',62.97,7.3,11.44,44.23,'Season 2024-2025. Yield/tree: 0.41 kg. Climate factor: 0.97. MQ index: 0.42.',NOW()),
('55034614-cd01-4a8f-8d01-27720c7da6f5','d5b78ba3-f094-4150-8cfb-e79b8e05331a','2021-2022','2022-01-14',106.33,16.95,24.39,64.99,'Season 2021-2022. Yield/tree: 0.50 kg. Climate factor: 0.98. MQ index: 0.61.',NOW()),
('c6bf58fb-ca6c-4fc0-b733-97b915e28d34','d5b78ba3-f094-4150-8cfb-e79b8e05331a','2022-2023','2023-01-14',65.56,8.65,17.63,39.28,'Season 2022-2023. Yield/tree: 0.31 kg. Climate factor: 0.94. MQ index: 0.61.',NOW()),
('2e28b63d-9a0e-4867-ba13-8e516c0eed57','d5b78ba3-f094-4150-8cfb-e79b8e05331a','2023-2024','2023-12-19',127.61,16.07,26.24,85.31,'Season 2023-2024. Yield/tree: 0.60 kg. Climate factor: 1.13. MQ index: 0.61.',NOW()),
('45152011-c704-467d-955e-8973557bb320','d5b78ba3-f094-4150-8cfb-e79b8e05331a','2024-2025','2024-11-24',151.94,23.13,51.39,77.43,'Season 2024-2025. Yield/tree: 0.71 kg. Climate factor: 0.91. MQ index: 0.61.',NOW()),
('7e7813d2-6cdb-4380-a0b3-68be94561ea9','d854e252-4b42-43a9-95a4-562341d83c82','2021-2022','2022-01-06',30.1,2.53,11.24,16.33,'Season 2021-2022. Yield/tree: 0.17 kg. Climate factor: 0.94. MQ index: 0.22.',NOW()),
('196d7bb5-121e-44a5-b182-63e705fa69d8','d854e252-4b42-43a9-95a4-562341d83c82','2022-2023','2022-10-27',37.11,5.57,7.21,24.33,'Season 2022-2023. Yield/tree: 0.21 kg. Climate factor: 1.01. MQ index: 0.22.',NOW()),
('c352c42c-6d26-469e-9e17-f48294765391','d854e252-4b42-43a9-95a4-562341d83c82','2023-2024','2023-11-07',37.65,2.7,8.4,26.55,'Season 2023-2024. Yield/tree: 0.21 kg. Climate factor: 0.93. MQ index: 0.22.',NOW()),
('4ddab17d-c546-4a1e-b45d-be4f354a9e79','d854e252-4b42-43a9-95a4-562341d83c82','2024-2025','2024-10-14',40.47,3.29,10.15,27.03,'Season 2024-2025. Yield/tree: 0.23 kg. Climate factor: 1.07. MQ index: 0.22.',NOW()),
('dc7626ea-675c-4b09-91ee-da0bf2a2a9a7','22e9c997-c743-4c3d-972c-5b00f71b83bb','2023-2024','2024-01-01',109.43,5.25,35.84,68.34,'Season 2023-2024. Yield/tree: 0.48 kg. Climate factor: 0.88. MQ index: 0.90.',NOW()),
('009f201b-36af-4a5c-ab85-2233977befe4','22e9c997-c743-4c3d-972c-5b00f71b83bb','2024-2025','2024-10-22',189.01,28.84,56.51,103.65,'Season 2024-2025. Yield/tree: 0.84 kg. Climate factor: 1.14. MQ index: 0.90.',NOW()),
('a3564db0-e95b-42bd-bfe0-983d012126c2','93ef4210-a5f3-435a-b7b4-cd60cfdf75e7','2021-2022','2021-12-28',51.66,5.73,16.53,29.4,'Season 2021-2022. Yield/tree: 0.39 kg. Climate factor: 0.87. MQ index: 0.37.',NOW()),
('40230174-76b6-4a34-beeb-cf5e4916fc74','93ef4210-a5f3-435a-b7b4-cd60cfdf75e7','2022-2023','2022-10-15',22.89,2.23,7.99,12.67,'Season 2022-2023. Yield/tree: 0.17 kg. Climate factor: 1.02. MQ index: 0.37.',NOW()),
('084b8067-8451-4b19-9a14-ee4f2aeb9d78','93ef4210-a5f3-435a-b7b4-cd60cfdf75e7','2023-2024','2023-12-03',31.8,2.25,9.78,19.77,'Season 2023-2024. Yield/tree: 0.24 kg. Climate factor: 1.12. MQ index: 0.37.',NOW()),
('6404708b-9a03-43ba-ba8d-6e717a2098f0','93ef4210-a5f3-435a-b7b4-cd60cfdf75e7','2024-2025','2024-10-30',74.74,6.46,15.85,52.43,'Season 2024-2025. Yield/tree: 0.57 kg. Climate factor: 1.14. MQ index: 0.37.',NOW()),
('3a33c893-6fa6-4e7d-aafa-11764db9cb6a','80fdd0ec-9bb0-4ef6-84b8-58c1fc8012d8','2021-2022','2022-01-08',26.97,2.58,9.4,14.99,'Season 2021-2022. Yield/tree: 0.41 kg. Climate factor: 1.11. MQ index: 0.39.',NOW()),
('df72c208-1c90-4ecd-ad74-81ccbcdd58d4','80fdd0ec-9bb0-4ef6-84b8-58c1fc8012d8','2022-2023','2022-10-14',19.36,2.58,3.89,12.89,'Season 2022-2023. Yield/tree: 0.30 kg. Climate factor: 1.11. MQ index: 0.39.',NOW()),
('099d4268-4b02-456a-adeb-ad70bb4cf38c','80fdd0ec-9bb0-4ef6-84b8-58c1fc8012d8','2023-2024','2023-11-10',29.25,3.09,6.9,19.27,'Season 2023-2024. Yield/tree: 0.45 kg. Climate factor: 1.11. MQ index: 0.39.',NOW()),
('9f766e01-1968-4a3c-b46f-06841a011518','80fdd0ec-9bb0-4ef6-84b8-58c1fc8012d8','2024-2025','2024-11-12',18.71,1.7,3.57,13.44,'Season 2024-2025. Yield/tree: 0.29 kg. Climate factor: 0.92. MQ index: 0.39.',NOW()),
('3c08c98d-ee24-4864-91e9-c559263d0a86','28bbdc75-5746-4aa3-b264-d527dd716759','2021-2022','2021-10-18',105.35,15.92,26.81,62.62,'Season 2021-2022. Yield/tree: 0.63 kg. Climate factor: 0.96. MQ index: 0.68.',NOW()),
('e492786c-3337-405d-a7ca-4805ae1f1790','28bbdc75-5746-4aa3-b264-d527dd716759','2022-2023','2022-10-23',62.38,10.35,15.2,36.84,'Season 2022-2023. Yield/tree: 0.37 kg. Climate factor: 0.88. MQ index: 0.68.',NOW()),
('51b69a11-60d3-4fd8-b4b9-794a40009b98','28bbdc75-5746-4aa3-b264-d527dd716759','2023-2024','2023-10-26',122.12,14.52,46.21,61.39,'Season 2023-2024. Yield/tree: 0.73 kg. Climate factor: 1.03. MQ index: 0.68.',NOW()),
('2579bd48-99e1-495d-b136-258171d0ea41','28bbdc75-5746-4aa3-b264-d527dd716759','2024-2025','2024-12-15',73.67,10.35,11.6,51.72,'Season 2024-2025. Yield/tree: 0.44 kg. Climate factor: 0.97. MQ index: 0.68.',NOW()),
('eaf12497-9c7d-428e-a93a-a42abe8f9a62','86fa9300-20a7-4346-980e-5cc4a0a83379','2023-2024','2024-01-05',28.22,2.05,6.75,19.42,'Season 2023-2024. Yield/tree: 0.17 kg. Climate factor: 1.06. MQ index: 0.15.',NOW()),
('d173e835-e159-4779-90cd-a11463d356a6','86fa9300-20a7-4346-980e-5cc4a0a83379','2024-2025','2024-12-11',30.15,1.98,10.03,18.14,'Season 2024-2025. Yield/tree: 0.18 kg. Climate factor: 1.13. MQ index: 0.15.',NOW()),
('58dd41ed-2d00-471d-9502-046762c4c5c6','fea50ed8-b11c-4586-a273-0b58edbee8de','2023-2024','2023-12-04',109.41,11.39,23.42,74.6,'Season 2023-2024. Yield/tree: 0.45 kg. Climate factor: 0.94. MQ index: 0.66.',NOW()),
('22b1a46b-ebe8-4834-8635-f4ac6f053a08','fea50ed8-b11c-4586-a273-0b58edbee8de','2024-2025','2024-11-28',189.21,16.88,54.11,118.22,'Season 2024-2025. Yield/tree: 0.77 kg. Climate factor: 1.05. MQ index: 0.66.',NOW()),
('081f4d8e-2007-4c30-b677-ff514831ec17','589e2f16-9656-4c94-8549-50db17ce2be5','2021-2022','2022-01-06',51.08,6.42,15.25,29.41,'Season 2021-2022. Yield/tree: 0.51 kg. Climate factor: 1.01. MQ index: 0.85.',NOW()),
('54204f98-36da-4992-a39d-0bb89b44292e','589e2f16-9656-4c94-8549-50db17ce2be5','2022-2023','2023-01-12',84.7,11.3,27.86,45.54,'Season 2022-2023. Yield/tree: 0.85 kg. Climate factor: 0.95. MQ index: 0.85.',NOW()),
('9aa62d2c-0a73-40bb-9721-12b46eeae6ae','589e2f16-9656-4c94-8549-50db17ce2be5','2023-2024','2024-01-16',60.1,8.65,15.8,35.65,'Season 2023-2024. Yield/tree: 0.60 kg. Climate factor: 0.90. MQ index: 0.85.',NOW()),
('05e89b48-3b50-476c-a8a2-77733f9fd5ba','589e2f16-9656-4c94-8549-50db17ce2be5','2024-2025','2024-12-07',90.82,8.19,17.43,65.2,'Season 2024-2025. Yield/tree: 0.91 kg. Climate factor: 0.92. MQ index: 0.85.',NOW()),
('98da48fd-1e38-4eb8-8157-757d232fa9c1','d9be44b6-82e3-4fbd-b6e6-db875863b861','2023-2024','2024-01-11',59.83,8.64,16.15,35.04,'Season 2023-2024. Yield/tree: 0.28 kg. Climate factor: 1.03. MQ index: 0.34.',NOW()),
('d3ca8168-2556-42fa-9f92-f852629fff1a','d9be44b6-82e3-4fbd-b6e6-db875863b861','2024-2025','2024-10-21',50.39,5.96,8.12,36.31,'Season 2024-2025. Yield/tree: 0.23 kg. Climate factor: 1.06. MQ index: 0.34.',NOW()),
('7ccd003b-3bf4-4ccf-9024-e2853fb9007b','5074b97e-3c29-49c0-bfa4-034931344665','2023-2024','2023-12-22',45.7,7.04,13.16,25.5,'Season 2023-2024. Yield/tree: 1.06 kg. Climate factor: 1.08. MQ index: 0.95.',NOW()),
('2daa89ca-a78a-483c-b9ca-f8db10b84c86','5074b97e-3c29-49c0-bfa4-034931344665','2024-2025','2024-12-18',33.12,5.38,10.44,17.3,'Season 2024-2025. Yield/tree: 0.77 kg. Climate factor: 0.92. MQ index: 0.95.',NOW()),
('6803c269-5f08-44ae-8310-f61810af0e16','82eed5d7-d586-49f2-913f-78e555f7ed13','2023-2024','2023-12-15',108.0,13.46,32.63,61.92,'Season 2023-2024. Yield/tree: 0.65 kg. Climate factor: 1.03. MQ index: 0.53.',NOW()),
('53fc2b75-6ffc-4d8d-a2af-c004411fa824','82eed5d7-d586-49f2-913f-78e555f7ed13','2024-2025','2024-12-04',75.02,6.23,24.85,43.94,'Season 2024-2025. Yield/tree: 0.45 kg. Climate factor: 0.98. MQ index: 0.53.',NOW()),
('3d81fdad-e375-4804-b796-fd2bcbef2903','62d7b93f-9ae3-4c18-9a74-3091844c4e33','2021-2022','2022-01-03',143.65,21.55,41.16,80.95,'Season 2021-2022. Yield/tree: 0.65 kg. Climate factor: 0.93. MQ index: 0.77.',NOW()),
('b72ccc57-85dc-4a77-8f7d-ede565e1a9c5','62d7b93f-9ae3-4c18-9a74-3091844c4e33','2022-2023','2022-12-18',172.44,17.4,44.77,110.28,'Season 2022-2023. Yield/tree: 0.78 kg. Climate factor: 0.92. MQ index: 0.77.',NOW()),
('bb293950-ca7b-4247-ac17-92a1f73b5c0e','62d7b93f-9ae3-4c18-9a74-3091844c4e33','2023-2024','2023-12-04',102.43,9.14,24.32,68.98,'Season 2023-2024. Yield/tree: 0.46 kg. Climate factor: 0.87. MQ index: 0.77.',NOW()),
('68275a24-e269-4d80-a30f-d1c78a982e2c','62d7b93f-9ae3-4c18-9a74-3091844c4e33','2024-2025','2024-12-21',136.44,13.26,37.18,86.0,'Season 2024-2025. Yield/tree: 0.61 kg. Climate factor: 0.97. MQ index: 0.77.',NOW()),
('ec172214-a7ce-44c7-99f5-826f400baf2b','1dd73c5f-8111-403e-abd0-41107e938273','2021-2022','2021-11-29',45.19,5.36,11.88,27.95,'Season 2021-2022. Yield/tree: 0.57 kg. Climate factor: 1.13. MQ index: 0.47.',NOW()),
('89c4beb3-d267-4430-be70-0c53c9bfbdcd','1dd73c5f-8111-403e-abd0-41107e938273','2022-2023','2023-01-12',43.5,6.16,11.8,25.54,'Season 2022-2023. Yield/tree: 0.55 kg. Climate factor: 0.94. MQ index: 0.47.',NOW()),
('12026564-9d5a-4cca-8be0-002135eebbb5','1dd73c5f-8111-403e-abd0-41107e938273','2023-2024','2023-10-15',21.59,1.91,5.56,14.12,'Season 2023-2024. Yield/tree: 0.27 kg. Climate factor: 1.01. MQ index: 0.47.',NOW()),
('973004eb-311a-4fb9-86ec-577c706fe322','1dd73c5f-8111-403e-abd0-41107e938273','2024-2025','2024-10-24',42.74,5.57,13.86,23.31,'Season 2024-2025. Yield/tree: 0.54 kg. Climate factor: 0.97. MQ index: 0.47.',NOW()),
('9396c99a-31d5-4073-8881-1e9f8f00823b','f0e659d5-af04-4a13-9b66-75d985f34efb','2023-2024','2023-10-22',87.61,10.16,25.14,52.3,'Season 2023-2024. Yield/tree: 0.53 kg. Climate factor: 1.14. MQ index: 0.40.',NOW()),
('d1e47881-5707-4eaf-95b8-8ebf27b524dc','f0e659d5-af04-4a13-9b66-75d985f34efb','2024-2025','2024-11-04',56.92,3.52,14.03,39.37,'Season 2024-2025. Yield/tree: 0.35 kg. Climate factor: 1.04. MQ index: 0.40.',NOW()),
('49128441-4ac0-420f-ae45-8af50a362029','3ff6da60-1fa3-4113-94cb-b85fb9fbc66a','2023-2024','2023-12-04',23.66,2.01,8.39,13.25,'Season 2023-2024. Yield/tree: 0.30 kg. Climate factor: 0.99. MQ index: 0.27.',NOW()),
('8d786e72-2ab7-457c-8db6-59daf4b085f7','3ff6da60-1fa3-4113-94cb-b85fb9fbc66a','2024-2025','2024-11-21',12.0,1.26,4.78,5.97,'Season 2024-2025. Yield/tree: 0.15 kg. Climate factor: 0.93. MQ index: 0.27.',NOW()),
('171ab3f1-3afb-49d0-b194-e31236bd572b','0b0bf418-c4a6-4215-9430-a0bd47277df7','2021-2022','2021-11-15',30.45,1.55,5.17,23.73,'Season 2021-2022. Yield/tree: 0.15 kg. Climate factor: 0.92. MQ index: 0.01.',NOW()),
('eb30473d-6ccc-4bbf-b4da-a830e539e264','0b0bf418-c4a6-4215-9430-a0bd47277df7','2022-2023','2022-12-21',30.45,1.8,8.27,20.37,'Season 2022-2023. Yield/tree: 0.15 kg. Climate factor: 0.91. MQ index: 0.01.',NOW()),
('041d36ff-8401-452a-b7f0-4bcdfe00a9ba','0b0bf418-c4a6-4215-9430-a0bd47277df7','2023-2024','2024-01-15',30.45,2.36,7.91,20.18,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 1.13. MQ index: 0.01.',NOW()),
('c9c1d1ba-d6e3-466b-b9be-04f0d4d37624','0b0bf418-c4a6-4215-9430-a0bd47277df7','2024-2025','2024-11-16',30.45,2.22,7.77,20.46,'Season 2024-2025. Yield/tree: 0.15 kg. Climate factor: 1.07. MQ index: 0.01.',NOW()),
('c024a0bc-1068-4599-a65b-ad16004f8bff','163a16ab-b56f-4662-8401-5efe215a4f23','2023-2024','2023-12-26',9.29,1.41,1.96,5.92,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 1.02. MQ index: 0.20.',NOW()),
('7c881ee3-909d-40ab-82d6-b6dc3dddb82b','163a16ab-b56f-4662-8401-5efe215a4f23','2024-2025','2024-12-23',9.15,1.14,2.92,5.09,'Season 2024-2025. Yield/tree: 0.15 kg. Climate factor: 1.06. MQ index: 0.20.',NOW()),
('49f91982-a23c-445a-883f-454aa989da09','6304d717-5d9e-42b6-8c4e-1ddc9b603a09','2023-2024','2024-01-04',104.89,7.15,31.46,66.28,'Season 2023-2024. Yield/tree: 0.96 kg. Climate factor: 1.09. MQ index: 0.99.',NOW()),
('c68ccc1f-b1f4-4440-bbc8-2482b5ef8b39','6304d717-5d9e-42b6-8c4e-1ddc9b603a09','2024-2025','2024-10-21',77.02,12.98,26.18,37.86,'Season 2024-2025. Yield/tree: 0.71 kg. Climate factor: 0.96. MQ index: 0.99.',NOW()),
('83fc1448-91c7-4a9e-8ad1-d9edb85a6c45','de144329-9a84-4ee1-8771-b1ff9e54b714','2021-2022','2021-11-06',149.14,16.94,32.23,99.97,'Season 2021-2022. Yield/tree: 0.59 kg. Climate factor: 0.98. MQ index: 0.53.',NOW()),
('28003cf6-554a-4dc9-9f7b-09990a91ed7f','de144329-9a84-4ee1-8771-b1ff9e54b714','2022-2023','2022-12-10',102.01,14.41,28.02,59.57,'Season 2022-2023. Yield/tree: 0.40 kg. Climate factor: 1.07. MQ index: 0.53.',NOW()),
('96caa831-8766-4a8b-a66c-4191cd4f1d92','de144329-9a84-4ee1-8771-b1ff9e54b714','2023-2024','2023-10-23',122.65,12.46,28.66,81.53,'Season 2023-2024. Yield/tree: 0.48 kg. Climate factor: 0.99. MQ index: 0.53.',NOW()),
('8e0e4144-5854-4eb2-8a04-8f5be3c29da9','de144329-9a84-4ee1-8771-b1ff9e54b714','2024-2025','2024-11-20',141.85,17.29,41.68,82.88,'Season 2024-2025. Yield/tree: 0.56 kg. Climate factor: 0.93. MQ index: 0.53.',NOW()),
('8fb7cb5d-21e3-4337-9067-59f68ad8284c','6cac8d82-bb3e-47fc-a172-412d77db327b','2023-2024','2023-11-24',41.2,3.6,12.96,24.65,'Season 2023-2024. Yield/tree: 0.22 kg. Climate factor: 0.86. MQ index: 0.46.',NOW()),
('56aee8a2-d488-4c23-9cc8-dd9c4ab4100c','6cac8d82-bb3e-47fc-a172-412d77db327b','2024-2025','2024-11-01',101.94,11.89,27.3,62.75,'Season 2024-2025. Yield/tree: 0.55 kg. Climate factor: 0.93. MQ index: 0.46.',NOW()),
('b5bdaa2b-ebe1-4ba0-b0f7-9dfd87087e14','258ea41a-b7ef-4ff1-b812-326c1e8b297e','2021-2022','2022-01-05',54.05,8.46,17.06,28.52,'Season 2021-2022. Yield/tree: 0.64 kg. Climate factor: 0.88. MQ index: 0.90.',NOW()),
('60c608cf-a89b-4098-9299-1113a19a64c0','258ea41a-b7ef-4ff1-b812-326c1e8b297e','2022-2023','2022-11-10',34.92,3.93,9.65,21.34,'Season 2022-2023. Yield/tree: 0.42 kg. Climate factor: 1.06. MQ index: 0.90.',NOW()),
('3b4c0555-7a61-4b7f-a596-6f60d14a3a9a','258ea41a-b7ef-4ff1-b812-326c1e8b297e','2023-2024','2024-01-15',56.36,7.76,15.76,32.84,'Season 2023-2024. Yield/tree: 0.67 kg. Climate factor: 0.94. MQ index: 0.90.',NOW()),
('3504c815-ee99-47e8-a4f0-80909d268ab8','258ea41a-b7ef-4ff1-b812-326c1e8b297e','2024-2025','2025-01-08',64.24,7.33,15.76,41.15,'Season 2024-2025. Yield/tree: 0.76 kg. Climate factor: 1.02. MQ index: 0.90.',NOW()),
('6f168d56-eb60-4eca-8b7a-60ca94a66242','ca59205f-b5e7-42fb-ab16-ffa5961d6898','2021-2022','2021-11-11',51.3,7.2,11.56,32.54,'Season 2021-2022. Yield/tree: 0.44 kg. Climate factor: 0.91. MQ index: 0.61.',NOW()),
('be12b927-4cd2-4f84-aed3-2c061f63fd5f','ca59205f-b5e7-42fb-ab16-ffa5961d6898','2022-2023','2022-10-22',71.98,10.08,20.64,41.26,'Season 2022-2023. Yield/tree: 0.62 kg. Climate factor: 1.07. MQ index: 0.61.',NOW()),
('66823f21-b9d0-4bf5-aa1f-90c9d9f17aa5','ca59205f-b5e7-42fb-ab16-ffa5961d6898','2023-2024','2023-10-28',52.05,5.34,15.8,30.91,'Season 2023-2024. Yield/tree: 0.45 kg. Climate factor: 1.10. MQ index: 0.61.',NOW()),
('6e8338d3-24b9-4fb5-9fbe-9c757d9d3f79','ca59205f-b5e7-42fb-ab16-ffa5961d6898','2024-2025','2024-12-09',64.54,8.73,13.7,42.12,'Season 2024-2025. Yield/tree: 0.56 kg. Climate factor: 0.93. MQ index: 0.61.',NOW()),
('d1311ab8-aafa-43c1-a12c-a9f8db98034a','dea8cd83-49a4-4dc2-9218-84c02c4f2336','2021-2022','2021-10-21',41.19,5.6,11.09,24.5,'Season 2021-2022. Yield/tree: 0.51 kg. Climate factor: 0.88. MQ index: 0.98.',NOW()),
('f1c65e43-8ef2-41b9-ae60-eed96a9ef9b1','dea8cd83-49a4-4dc2-9218-84c02c4f2336','2022-2023','2022-12-22',39.99,3.02,11.73,25.24,'Season 2022-2023. Yield/tree: 0.49 kg. Climate factor: 0.93. MQ index: 0.98.',NOW()),
('1ec177d1-d286-427a-87fa-d3d1bb38dc44','dea8cd83-49a4-4dc2-9218-84c02c4f2336','2023-2024','2023-11-12',39.75,5.72,10.44,23.58,'Season 2023-2024. Yield/tree: 0.49 kg. Climate factor: 1.04. MQ index: 0.98.',NOW()),
('9306e5d2-b1a8-4401-a79e-9fe6942f4291','dea8cd83-49a4-4dc2-9218-84c02c4f2336','2024-2025','2024-12-13',71.32,11.64,17.62,42.06,'Season 2024-2025. Yield/tree: 0.88 kg. Climate factor: 0.89. MQ index: 0.98.',NOW()),
('17d7f2e1-9459-420d-b425-aace842cb155','4ce4fd5a-374a-4ee3-8019-5043952959ff','2021-2022','2021-12-26',54.72,6.21,13.69,34.82,'Season 2021-2022. Yield/tree: 0.23 kg. Climate factor: 0.96. MQ index: 0.36.',NOW()),
('85975f60-086b-41aa-989f-7ac955f21fc2','4ce4fd5a-374a-4ee3-8019-5043952959ff','2022-2023','2022-11-06',100.58,15.71,22.08,62.79,'Season 2022-2023. Yield/tree: 0.42 kg. Climate factor: 1.04. MQ index: 0.36.',NOW()),
('eab02196-414c-441b-b2f7-db43e194614c','4ce4fd5a-374a-4ee3-8019-5043952959ff','2023-2024','2023-12-03',44.6,4.93,9.38,30.29,'Season 2023-2024. Yield/tree: 0.19 kg. Climate factor: 0.93. MQ index: 0.36.',NOW()),
('4f6fe8d6-7e41-4843-9836-a883782cf422','4ce4fd5a-374a-4ee3-8019-5043952959ff','2024-2025','2025-01-05',59.3,5.05,17.36,36.9,'Season 2024-2025. Yield/tree: 0.25 kg. Climate factor: 0.99. MQ index: 0.36.',NOW()),
('4c531c35-03dd-4aa1-ade8-6aeaad224f36','a12d98ec-7714-4151-bc79-381deea83e33','2021-2022','2021-12-29',24.9,2.02,7.59,15.29,'Season 2021-2022. Yield/tree: 0.15 kg. Climate factor: 1.11. MQ index: 0.22.',NOW()),
('e2f839ac-5847-40bf-92ad-065d3806757f','a12d98ec-7714-4151-bc79-381deea83e33','2022-2023','2022-11-13',32.14,3.29,8.88,19.97,'Season 2022-2023. Yield/tree: 0.19 kg. Climate factor: 1.05. MQ index: 0.22.',NOW()),
('1ed30ace-8dd7-4d1c-9ce0-3f5a8cfd98e1','a12d98ec-7714-4151-bc79-381deea83e33','2023-2024','2023-12-23',24.9,2.1,7.36,15.44,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 1.10. MQ index: 0.22.',NOW()),
('fea4f1f5-1fe6-4430-9d9d-af4b87589731','a12d98ec-7714-4151-bc79-381deea83e33','2024-2025','2024-11-11',34.62,2.92,8.26,23.44,'Season 2024-2025. Yield/tree: 0.21 kg. Climate factor: 1.13. MQ index: 0.22.',NOW()),
('12219f45-1168-42b6-ae64-f7da3e9863c1','0274bf00-1a00-40e6-a257-59fa64fa9ac2','2021-2022','2021-11-25',78.47,5.26,22.1,51.11,'Season 2021-2022. Yield/tree: 0.41 kg. Climate factor: 1.00. MQ index: 0.92.',NOW()),
('ab261b4c-25f8-4558-85dc-824566c9a662','0274bf00-1a00-40e6-a257-59fa64fa9ac2','2022-2023','2022-12-24',109.6,16.55,37.71,55.34,'Season 2022-2023. Yield/tree: 0.58 kg. Climate factor: 1.03. MQ index: 0.92.',NOW()),
('07fe8ca3-c226-4019-a1f0-de3e51ea6112','0274bf00-1a00-40e6-a257-59fa64fa9ac2','2023-2024','2024-01-16',199.6,22.0,37.96,139.64,'Season 2023-2024. Yield/tree: 1.05 kg. Climate factor: 1.14. MQ index: 0.92.',NOW()),
('dda5bd66-29d3-485a-a368-404c5594acfb','0274bf00-1a00-40e6-a257-59fa64fa9ac2','2024-2025','2024-12-02',132.54,14.75,51.92,65.87,'Season 2024-2025. Yield/tree: 0.70 kg. Climate factor: 0.90. MQ index: 0.92.',NOW()),
('3255141a-4f01-4ee6-85d0-bcb49998597c','9c565b1c-51d3-4cd3-b206-6712f115bf66','2023-2024','2024-01-05',18.3,1.54,4.14,12.62,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 1.04. MQ index: 0.16.',NOW()),
('e677fc90-03f7-4fd4-a691-cbc14cbeb739','9c565b1c-51d3-4cd3-b206-6712f115bf66','2024-2025','2024-11-28',18.3,1.75,5.06,11.49,'Season 2024-2025. Yield/tree: 0.15 kg. Climate factor: 0.88. MQ index: 0.16.',NOW()),
('20c45b1f-8986-42a6-abaa-4614cc54c4c9','80d74c12-eba9-42a8-842c-6f289b6eb41d','2021-2022','2021-12-05',31.47,3.5,8.13,19.84,'Season 2021-2022. Yield/tree: 0.67 kg. Climate factor: 1.09. MQ index: 0.79.',NOW()),
('3f5336f7-a48d-4bbb-ac5b-b50836b1d859','80d74c12-eba9-42a8-842c-6f289b6eb41d','2022-2023','2022-10-16',17.93,2.84,5.01,10.08,'Season 2022-2023. Yield/tree: 0.38 kg. Climate factor: 1.11. MQ index: 0.79.',NOW()),
('2fe7214e-3ec4-4ea6-9647-14018464a9be','80d74c12-eba9-42a8-842c-6f289b6eb41d','2023-2024','2023-11-07',34.13,4.79,10.94,18.4,'Season 2023-2024. Yield/tree: 0.73 kg. Climate factor: 0.91. MQ index: 0.79.',NOW()),
('e7d541ee-bc19-45cf-a163-75597faf137a','80d74c12-eba9-42a8-842c-6f289b6eb41d','2024-2025','2024-10-11',23.12,3.69,6.53,12.9,'Season 2024-2025. Yield/tree: 0.49 kg. Climate factor: 0.93. MQ index: 0.79.',NOW()),
('4d04e623-37af-4f7e-9dfa-2e55460e8e0f','a7b8fac6-1745-416f-8eed-a4426de4f0b1','2021-2022','2021-12-24',74.38,6.32,20.82,47.24,'Season 2021-2022. Yield/tree: 0.40 kg. Climate factor: 1.14. MQ index: 0.60.',NOW()),
('1bdd1952-3ce4-4329-a474-f4bf5194b2e1','a7b8fac6-1745-416f-8eed-a4426de4f0b1','2022-2023','2022-12-31',126.74,9.9,45.47,71.37,'Season 2022-2023. Yield/tree: 0.69 kg. Climate factor: 0.97. MQ index: 0.60.',NOW()),
('2533923f-976a-4100-88c2-068c409c9dd0','a7b8fac6-1745-416f-8eed-a4426de4f0b1','2023-2024','2023-12-12',120.22,14.51,28.99,76.72,'Season 2023-2024. Yield/tree: 0.65 kg. Climate factor: 1.10. MQ index: 0.60.',NOW()),
('3994f984-afb6-4718-a131-57ed2165975c','a7b8fac6-1745-416f-8eed-a4426de4f0b1','2024-2025','2024-12-12',115.69,12.74,40.48,62.47,'Season 2024-2025. Yield/tree: 0.63 kg. Climate factor: 1.14. MQ index: 0.60.',NOW()),
('f1cc5f1e-ee98-4c45-b656-b8f7b3dd2d1c','1caee4c8-5f87-46f0-9aa3-1c1521c87055','2021-2022','2021-11-27',58.47,9.48,20.2,28.79,'Season 2021-2022. Yield/tree: 0.45 kg. Climate factor: 1.07. MQ index: 0.98.',NOW()),
('cdc34b69-92b2-4f58-ab34-9aded205bcb5','1caee4c8-5f87-46f0-9aa3-1c1521c87055','2022-2023','2022-12-24',174.1,19.83,45.61,108.66,'Season 2022-2023. Yield/tree: 1.33 kg. Climate factor: 1.13. MQ index: 0.98.',NOW()),
('d9f3118c-6993-444f-9498-2cecc924761a','1caee4c8-5f87-46f0-9aa3-1c1521c87055','2023-2024','2023-11-23',150.13,19.95,43.93,86.25,'Season 2023-2024. Yield/tree: 1.15 kg. Climate factor: 1.02. MQ index: 0.98.',NOW()),
('130e034b-e971-4500-b7c0-a7cdfaf37f0d','1caee4c8-5f87-46f0-9aa3-1c1521c87055','2024-2025','2025-01-05',111.65,13.26,26.68,71.7,'Season 2024-2025. Yield/tree: 0.85 kg. Climate factor: 1.02. MQ index: 0.98.',NOW()),
('eeed5d1d-76bb-4aed-94bb-6bb70ce6576b','2bc7aab7-2a95-42c5-9c37-29f1d9d15a47','2021-2022','2021-12-14',225.47,28.75,59.52,137.2,'Season 2021-2022. Yield/tree: 0.96 kg. Climate factor: 0.92. MQ index: 0.94.',NOW()),
('0a724230-5a25-4edb-9f69-af4c31bb50a1','2bc7aab7-2a95-42c5-9c37-29f1d9d15a47','2022-2023','2022-10-29',191.1,28.91,64.53,97.65,'Season 2022-2023. Yield/tree: 0.81 kg. Climate factor: 1.06. MQ index: 0.94.',NOW()),
('5ef0ac22-2faa-43af-88c6-cf8f09acd778','2bc7aab7-2a95-42c5-9c37-29f1d9d15a47','2023-2024','2023-12-07',171.29,24.82,59.4,87.07,'Season 2023-2024. Yield/tree: 0.73 kg. Climate factor: 1.00. MQ index: 0.94.',NOW()),
('0e731dc3-0c76-4ee9-aab3-e29e98f93f16','2bc7aab7-2a95-42c5-9c37-29f1d9d15a47','2024-2025','2024-10-27',88.5,8.13,30.72,49.65,'Season 2024-2025. Yield/tree: 0.37 kg. Climate factor: 0.88. MQ index: 0.94.',NOW()),
('7133e5a3-c5a5-4f81-b1a8-84f887798329','48e1cc01-80fc-44ee-94ad-66a8818a587a','2021-2022','2021-10-25',66.2,8.81,17.43,39.96,'Season 2021-2022. Yield/tree: 0.36 kg. Climate factor: 0.87. MQ index: 0.66.',NOW()),
('a678ae6f-4638-4210-9710-a03313e0943d','48e1cc01-80fc-44ee-94ad-66a8818a587a','2022-2023','2023-01-09',171.04,19.28,42.95,108.82,'Season 2022-2023. Yield/tree: 0.93 kg. Climate factor: 1.11. MQ index: 0.66.',NOW()),
('8963138a-3b23-4b52-a4eb-5127da24276f','48e1cc01-80fc-44ee-94ad-66a8818a587a','2023-2024','2024-01-07',114.12,15.13,27.06,71.93,'Season 2023-2024. Yield/tree: 0.62 kg. Climate factor: 1.12. MQ index: 0.66.',NOW()),
('66137b6c-c35d-44a6-80a1-5b85ef04437e','48e1cc01-80fc-44ee-94ad-66a8818a587a','2024-2025','2024-12-28',161.33,18.97,33.3,109.06,'Season 2024-2025. Yield/tree: 0.88 kg. Climate factor: 1.13. MQ index: 0.66.',NOW()),
('377986b9-371b-42bc-84c0-6a029685062d','c74959ef-9dec-4c60-97fb-fa4942d81a9e','2021-2022','2021-11-25',21.15,1.55,3.59,16.0,'Season 2021-2022. Yield/tree: 0.15 kg. Climate factor: 1.06. MQ index: 0.04.',NOW()),
('d95e9c2f-d701-4e8f-b35e-6e3ea24c42e1','c74959ef-9dec-4c60-97fb-fa4942d81a9e','2022-2023','2022-12-21',21.15,1.32,5.26,14.57,'Season 2022-2023. Yield/tree: 0.15 kg. Climate factor: 1.09. MQ index: 0.04.',NOW()),
('4a9d30aa-226b-4b91-98b5-caf0479c71c0','c74959ef-9dec-4c60-97fb-fa4942d81a9e','2023-2024','2024-01-07',21.15,2.13,4.79,14.24,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 1.05. MQ index: 0.04.',NOW()),
('df011a30-7aab-4a35-a93e-4855b93a1945','c74959ef-9dec-4c60-97fb-fa4942d81a9e','2024-2025','2024-11-09',21.15,1.83,4.42,14.9,'Season 2024-2025. Yield/tree: 0.15 kg. Climate factor: 0.92. MQ index: 0.04.',NOW()),
('cfee9a61-ec1d-4cda-adac-9fe023e291a8','058bcdad-90b0-438c-8016-e16bcaf6a90c','2021-2022','2021-10-24',29.25,2.1,7.33,19.82,'Season 2021-2022. Yield/tree: 0.15 kg. Climate factor: 1.05. MQ index: 0.02.',NOW()),
('25901fec-33a8-4c74-b512-330d428bf8fa','058bcdad-90b0-438c-8016-e16bcaf6a90c','2022-2023','2022-11-11',29.25,3.01,6.77,19.47,'Season 2022-2023. Yield/tree: 0.15 kg. Climate factor: 0.98. MQ index: 0.02.',NOW()),
('7a57cd07-3848-4701-a45b-2557edfdbbe2','058bcdad-90b0-438c-8016-e16bcaf6a90c','2023-2024','2023-11-29',29.25,3.83,5.48,19.94,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 0.99. MQ index: 0.02.',NOW()),
('761bb421-290c-4205-aebf-d1b6d406bc35','058bcdad-90b0-438c-8016-e16bcaf6a90c','2024-2025','2024-12-31',29.25,2.12,10.73,16.39,'Season 2024-2025. Yield/tree: 0.15 kg. Climate factor: 1.02. MQ index: 0.02.',NOW()),
('875dc514-094d-438e-aee6-178f6d8bed34','f4314371-80de-47b9-a67e-aed954435440','2023-2024','2023-12-28',56.03,7.6,20.69,27.73,'Season 2023-2024. Yield/tree: 0.49 kg. Climate factor: 0.97. MQ index: 0.47.',NOW()),
('199aa5f4-d669-4e22-b943-d8f289729713','f4314371-80de-47b9-a67e-aed954435440','2024-2025','2024-11-22',76.83,10.41,17.55,48.87,'Season 2024-2025. Yield/tree: 0.67 kg. Climate factor: 1.07. MQ index: 0.47.',NOW()),
('a4a40d04-97d8-4ea8-b16f-265925126e6c','50d6a4c3-800d-4b97-bfda-b01d5ac9c0b3','2021-2022','2022-01-10',92.77,14.09,29.97,48.7,'Season 2021-2022. Yield/tree: 0.43 kg. Climate factor: 0.92. MQ index: 0.82.',NOW()),
('9c2faa9f-3955-45f5-866e-9ce93941c616','50d6a4c3-800d-4b97-bfda-b01d5ac9c0b3','2022-2023','2022-12-05',250.27,35.91,64.32,150.04,'Season 2022-2023. Yield/tree: 1.16 kg. Climate factor: 1.10. MQ index: 0.82.',NOW()),
('13fbdaed-7c1b-4532-86d2-f6c45f115ffd','50d6a4c3-800d-4b97-bfda-b01d5ac9c0b3','2023-2024','2023-12-04',73.56,12.03,19.13,42.4,'Season 2023-2024. Yield/tree: 0.34 kg. Climate factor: 0.86. MQ index: 0.82.',NOW()),
('db7de336-7799-4249-9b8b-81cfbac75626','50d6a4c3-800d-4b97-bfda-b01d5ac9c0b3','2024-2025','2024-11-11',142.72,24.36,41.43,76.93,'Season 2024-2025. Yield/tree: 0.66 kg. Climate factor: 0.90. MQ index: 0.82.',NOW()),
('c2416945-769d-44ac-9c36-fe720e9092a8','d0042b09-ec1d-4cf3-a59a-6277b33cba70','2023-2024','2024-01-15',5.1,0.46,1.55,3.09,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 1.10. MQ index: 0.08.',NOW()),
('5a163cc7-ad35-4610-b907-1880d6224d22','d0042b09-ec1d-4cf3-a59a-6277b33cba70','2024-2025','2024-11-05',5.1,0.29,1.49,3.32,'Season 2024-2025. Yield/tree: 0.15 kg. Climate factor: 1.11. MQ index: 0.08.',NOW()),
('e9b15303-b910-424b-abc7-bae4ff33a610','afdbcd84-ff38-4fcf-bc2a-b3af53fdfafe','2021-2022','2021-11-30',78.15,12.68,24.59,40.88,'Season 2021-2022. Yield/tree: 0.59 kg. Climate factor: 1.11. MQ index: 0.43.',NOW()),
('753c4c52-40ca-408f-a242-b98351248e40','afdbcd84-ff38-4fcf-bc2a-b3af53fdfafe','2022-2023','2023-01-13',32.91,2.47,8.11,22.33,'Season 2022-2023. Yield/tree: 0.25 kg. Climate factor: 0.88. MQ index: 0.43.',NOW()),
('573a348a-7972-40ed-914b-e361adc9f592','afdbcd84-ff38-4fcf-bc2a-b3af53fdfafe','2023-2024','2023-11-10',65.03,10.14,13.16,41.73,'Season 2023-2024. Yield/tree: 0.49 kg. Climate factor: 1.05. MQ index: 0.43.',NOW()),
('9a9b52bd-1e08-4284-973d-0bf76cb0102b','afdbcd84-ff38-4fcf-bc2a-b3af53fdfafe','2024-2025','2024-12-29',74.4,7.22,20.79,46.38,'Season 2024-2025. Yield/tree: 0.56 kg. Climate factor: 0.99. MQ index: 0.43.',NOW()),
('39bed61f-0f57-4932-acc9-91e66124b288','ee1c8684-863d-4bc2-8a76-56639743cfbf','2021-2022','2021-11-01',12.15,0.93,2.82,8.4,'Season 2021-2022. Yield/tree: 0.15 kg. Climate factor: 0.87. MQ index: 0.09.',NOW()),
('1096a681-0218-4849-9e09-47e109279ff3','ee1c8684-863d-4bc2-8a76-56639743cfbf','2022-2023','2022-12-17',12.15,0.76,2.55,8.85,'Season 2022-2023. Yield/tree: 0.15 kg. Climate factor: 0.86. MQ index: 0.09.',NOW()),
('a5856aab-2c22-43ce-a223-cb27fec81e15','ee1c8684-863d-4bc2-8a76-56639743cfbf','2023-2024','2023-12-04',12.15,1.42,4.25,6.48,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 0.89. MQ index: 0.09.',NOW()),
('0e492090-c04e-4084-a116-8f5b32f45424','ee1c8684-863d-4bc2-8a76-56639743cfbf','2024-2025','2024-12-25',12.15,1.3,3.78,7.07,'Season 2024-2025. Yield/tree: 0.15 kg. Climate factor: 1.03. MQ index: 0.09.',NOW()),
('e58a5e1a-c2b7-49d8-8c3c-464c0a797f2c','8f0c2ff0-760a-47d2-a144-3014c6031747','2021-2022','2021-11-14',5.55,0.52,1.38,3.64,'Season 2021-2022. Yield/tree: 0.15 kg. Climate factor: 0.97. MQ index: 0.31.',NOW()),
('94b63b76-4250-475e-90fb-d49eb6a28224','8f0c2ff0-760a-47d2-a144-3014c6031747','2022-2023','2022-11-24',13.03,1.4,4.82,6.81,'Season 2022-2023. Yield/tree: 0.35 kg. Climate factor: 1.11. MQ index: 0.31.',NOW()),
('6d31f62a-253a-4de9-be08-97740a1e2d5f','8f0c2ff0-760a-47d2-a144-3014c6031747','2023-2024','2023-10-23',11.74,1.83,3.7,6.21,'Season 2023-2024. Yield/tree: 0.32 kg. Climate factor: 0.87. MQ index: 0.31.',NOW()),
('051ea7f0-a0c5-43ce-84f9-36845455ac2e','8f0c2ff0-760a-47d2-a144-3014c6031747','2024-2025','2024-11-08',11.99,0.64,3.68,7.67,'Season 2024-2025. Yield/tree: 0.32 kg. Climate factor: 1.05. MQ index: 0.31.',NOW()),
('40a96481-cd7c-47d8-b7d5-d3b2526d82f4','835061c7-e763-4f15-8110-f6ea82c21ce0','2021-2022','2021-12-29',9.6,1.22,2.41,5.97,'Season 2021-2022. Yield/tree: 0.15 kg. Climate factor: 1.15. MQ index: 0.01.',NOW()),
('f7d0c8ef-f038-4fe4-b407-f8595b537997','835061c7-e763-4f15-8110-f6ea82c21ce0','2022-2023','2022-10-10',9.6,0.58,3.16,5.85,'Season 2022-2023. Yield/tree: 0.15 kg. Climate factor: 0.91. MQ index: 0.01.',NOW()),
('3592d10a-9654-4c1a-868d-cfad6396e3b4','835061c7-e763-4f15-8110-f6ea82c21ce0','2023-2024','2023-10-26',9.6,0.89,2.88,5.83,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 0.93. MQ index: 0.01.',NOW()),
('c5dffb4c-e9a2-45ec-b12e-b28ab93d8c75','835061c7-e763-4f15-8110-f6ea82c21ce0','2024-2025','2024-11-18',9.6,1.16,1.97,6.47,'Season 2024-2025. Yield/tree: 0.15 kg. Climate factor: 1.05. MQ index: 0.01.',NOW()),
('564efbe9-8b90-40c4-bfa5-2af05ecd8de9','123aa3d3-dab1-46a5-9b49-07c3695381db','2023-2024','2023-10-20',20.85,2.07,4.18,14.6,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 0.85. MQ index: 0.33.',NOW()),
('e28154be-c712-44a7-880f-7a697284841a','123aa3d3-dab1-46a5-9b49-07c3695381db','2024-2025','2024-12-25',42.27,2.97,10.94,28.36,'Season 2024-2025. Yield/tree: 0.30 kg. Climate factor: 0.99. MQ index: 0.33.',NOW()),
('356cee24-39b3-450d-b51c-fae092e22c8b','79f13140-a1e8-42bb-a80f-21dc4cd72ef3','2021-2022','2021-10-18',52.68,6.21,13.89,32.58,'Season 2021-2022. Yield/tree: 0.52 kg. Climate factor: 0.86. MQ index: 0.52.',NOW()),
('bf74dd3c-88b6-4feb-ac6d-1ef560eb5a0a','79f13140-a1e8-42bb-a80f-21dc4cd72ef3','2022-2023','2022-12-05',36.62,4.76,9.81,22.06,'Season 2022-2023. Yield/tree: 0.36 kg. Climate factor: 0.87. MQ index: 0.52.',NOW()),
('4170ac1f-0578-4484-bf5a-d2f6281983cb','79f13140-a1e8-42bb-a80f-21dc4cd72ef3','2023-2024','2024-01-01',39.66,2.68,9.44,27.54,'Season 2023-2024. Yield/tree: 0.39 kg. Climate factor: 0.87. MQ index: 0.52.',NOW()),
('6b0d23e6-08f6-4edc-aa87-addd06b0f954','79f13140-a1e8-42bb-a80f-21dc4cd72ef3','2024-2025','2024-12-11',43.14,5.31,10.41,27.42,'Season 2024-2025. Yield/tree: 0.43 kg. Climate factor: 1.03. MQ index: 0.52.',NOW()),
('2059330c-a2e8-4261-9c4b-b718efe5c069','a59b4841-8111-4535-a88e-6133736bb737','2021-2022','2021-12-24',19.06,2.58,5.26,11.21,'Season 2021-2022. Yield/tree: 0.19 kg. Climate factor: 1.03. MQ index: 0.20.',NOW()),
('9bf05a71-7f9e-4f57-9428-3c87aea8a741','a59b4841-8111-4535-a88e-6133736bb737','2022-2023','2022-12-07',17.28,1.34,3.97,11.97,'Season 2022-2023. Yield/tree: 0.18 kg. Climate factor: 1.07. MQ index: 0.20.',NOW()),
('e6ebd287-f345-4734-ac19-15a546949d6d','a59b4841-8111-4535-a88e-6133736bb737','2023-2024','2023-10-31',14.7,1.23,3.21,10.25,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 0.97. MQ index: 0.20.',NOW()),
('e8de0a54-378f-4fe1-b1a2-06709585390e','a59b4841-8111-4535-a88e-6133736bb737','2024-2025','2025-01-10',14.7,0.93,3.56,10.22,'Season 2024-2025. Yield/tree: 0.15 kg. Climate factor: 1.06. MQ index: 0.20.',NOW()),
('491ee2dc-76b6-4a1f-bb4b-00dd57c700c9','1f1f65dd-f84d-476e-b8cb-b47c34b42eb9','2023-2024','2024-01-05',11.61,1.94,3.39,6.27,'Season 2023-2024. Yield/tree: 0.31 kg. Climate factor: 0.96. MQ index: 0.79.',NOW()),
('e6293225-32f2-4d8b-9895-50289f1fb958','1f1f65dd-f84d-476e-b8cb-b47c34b42eb9','2024-2025','2025-01-08',26.71,4.0,9.11,13.6,'Season 2024-2025. Yield/tree: 0.72 kg. Climate factor: 0.89. MQ index: 0.79.',NOW()),
('60afe2a2-afe3-436c-b1c8-9fe443889e25','89f90985-203f-4aa7-a0b2-e7e5a3ff0ecb','2021-2022','2021-11-03',6.0,0.36,1.47,4.17,'Season 2021-2022. Yield/tree: 0.15 kg. Climate factor: 0.87. MQ index: 0.06.',NOW()),
('b3440b96-c322-4aff-a9aa-ad684ac9e7f9','89f90985-203f-4aa7-a0b2-e7e5a3ff0ecb','2022-2023','2023-01-15',6.0,0.78,1.35,3.87,'Season 2022-2023. Yield/tree: 0.15 kg. Climate factor: 1.05. MQ index: 0.06.',NOW()),
('cea20d8f-7423-49c8-9df8-adea487bed7e','89f90985-203f-4aa7-a0b2-e7e5a3ff0ecb','2023-2024','2023-12-30',6.0,0.58,1.76,3.66,'Season 2023-2024. Yield/tree: 0.15 kg. Climate factor: 0.93. MQ index: 0.06.',NOW()),
('f2636c19-d6e2-4fa5-81fe-c2fb2ee46d7e','89f90985-203f-4aa7-a0b2-e7e5a3ff0ecb','2024-2025','2024-11-11',6.0,0.88,1.86,3.27,'Season 2024-2025. Yield/tree: 0.15 kg. Climate factor: 1.03. MQ index: 0.06.',NOW())
ON CONFLICT (id) DO NOTHING;

-- CLUSTER STAGE DATA
INSERT INTO cluster_stage_data (id,cluster_id,season,date_planted,plant_age_months,number_of_plants,fertilizer_type,fertilizer_frequency,pesticide_type,pesticide_frequency,last_pruned_date,previous_pruned_date,pruning_interval_months,shade_tree_present,shade_tree_species,soil_ph,avg_temp_c,avg_rainfall_mm,avg_humidity_pct,actual_flowering_date,estimated_flowering_date,estimated_harvest_date,actual_harvest_date,pre_last_harvest_date,pre_total_trees,pre_yield_kg,pre_grade_fine,pre_grade_premium,pre_grade_commercial,previous_fine_pct,previous_premium_pct,previous_commercial_pct,defect_count,bean_moisture,bean_screen_size,predicted_yield,created_at,updated_at) VALUES
('532ce693-c265-4f43-b876-a87d6f2064f5','887a9498-d0ad-47de-80e4-754487e94ace','2021-2022','2010-07-01',135,51,'organic','rarely','non-organic','rarely','2011-11-18','2010-06-26',17,FALSE,NULL,6.51,20.67,243.86,81.57,'2021-12-19','2021-12-27','2022-08-15','2022-08-02',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,10,11.52,'Screen 15',29.61,NOW(),NOW()),
('bf5b12a8-d851-4216-97cd-a2b9ad8157cd','887a9498-d0ad-47de-80e4-754487e94ace','2022-2023','2010-07-01',147,51,'organic','rarely','non-organic','never','2022-02-02','2020-02-13',24,FALSE,NULL,6.35,22.37,255.25,72.91,'2023-02-14','2023-02-19','2023-11-15','2023-11-10','2022-01-09',49,12.54,1.08,3.76,7.69,8.63,30.01,61.36,42,11.73,'Screen 15',12.33,NOW(),NOW()),
('bdf272db-4a20-407e-8750-7f51cb9ff09c','887a9498-d0ad-47de-80e4-754487e94ace','2023-2024','2010-07-01',159,51,'organic','rarely','non-organic','never','2022-12-12','2021-03-22',21,FALSE,NULL,5.99,22.44,254.86,82.12,'2024-01-03','2024-01-07','2024-11-15','2024-11-24','2022-11-08',52,21.7,1.25,4.3,16.16,5.75,19.8,74.45,14,11.06,'Screen 16',24.32,NOW(),NOW()),
('325722cf-9c0a-485e-9562-e0b7341d54f5','887a9498-d0ad-47de-80e4-754487e94ace','2024-2025','2010-07-01',171,51,'organic','rarely','non-organic','rarely','2023-12-13','2022-07-21',17,FALSE,NULL,6.4,23.93,202.72,79.62,'2024-12-12','2024-12-18','2025-08-15','2025-08-18','2023-11-09',53,10.78,1.3,2.9,6.58,12.08,26.87,61.05,40,12.24,'Screen 16',11.18,NOW(),NOW()),
('c3414b9a-89f4-46cb-8908-dc464cce662b','ba3e9298-71fc-4632-ae12-884751d4d6d7','2021-2022','2013-06-28',100,49,'organic','never','organic','never','2015-02-19','2013-04-30',22,FALSE,NULL,5.63,20.94,279.49,81.68,'2022-01-27','2022-01-23','2022-09-15','2022-09-03',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,35,11.84,'Screen 15',19.87,NOW(),NOW()),
('da035e01-7887-4688-999d-e95ec170d43e','ba3e9298-71fc-4632-ae12-884751d4d6d7','2022-2023','2013-06-28',112,49,'organic','never','organic','never','2021-11-20','2019-11-01',25,FALSE,NULL,5.69,21.56,276.64,79.66,'2022-12-24','2022-12-27','2023-10-15','2023-10-28','2021-10-27',50,10.78,0.92,2.06,7.79,8.56,19.14,72.3,24,11.49,'Screen 16',11.09,NOW(),NOW()),
('381db0f0-bbf3-4ba0-9dfb-3a7fcc4be16e','ba3e9298-71fc-4632-ae12-884751d4d6d7','2023-2024','2013-06-28',124,49,'organic','never','organic','never','2022-11-27','2022-01-01',11,FALSE,NULL,6.16,23.89,172.45,76.53,'2024-02-03','2024-02-10','2024-11-15','2024-11-30','2022-10-25',50,7.35,0.41,1.81,5.13,5.64,24.58,69.78,19,12.08,'Screen 15',8.0,NOW(),NOW()),
('413e9361-6e72-410c-ad20-c890ac5b4f35','ba3e9298-71fc-4632-ae12-884751d4d6d7','2024-2025','2013-06-28',136,49,'organic','never','organic','never','2023-12-28','2022-07-06',18,FALSE,NULL,5.53,23.28,198.25,78.13,'2024-12-24','2024-12-27','2025-10-15','2025-10-12','2023-11-27',50,9.42,1.24,2.55,5.63,13.21,27.04,59.75,40,12.74,'Screen 17',10.78,NOW(),NOW()),
('4a873606-d2c5-4d6c-89d7-71d6d73b0dab','0c3bc855-8f53-40c7-a06c-625bf253f7ae','2021-2022','2019-05-21',29,145,'none','never','organic','never','2020-08-06','2018-11-15',21,FALSE,NULL,5.98,23.24,219.33,82.68,'2021-12-20','2021-12-25','2022-09-15','2022-09-02',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,12,11.78,'Screen 17',60.86,NOW(),NOW()),
('13438898-5dee-4dd8-953c-22d7a29d226a','0c3bc855-8f53-40c7-a06c-625bf253f7ae','2022-2023','2019-05-21',41,145,'none','never','organic','never','2021-12-09','2020-12-14',12,FALSE,NULL,6.27,19.66,213.66,74.98,'2022-12-05','2022-12-15','2023-10-15','2023-10-11','2021-11-04',144,21.75,2.03,6.83,12.9,9.32,31.39,59.29,27,12.17,'Screen 16',25.56,NOW(),NOW()),
('546df13a-6686-4ed5-8d6b-c3075864bde3','0c3bc855-8f53-40c7-a06c-625bf253f7ae','2023-2024','2019-05-21',53,145,'none','never','organic','never','2023-01-27','2021-07-06',19,FALSE,NULL,6.53,21.57,235.01,78.91,'2024-01-04','2024-01-06','2024-09-15','2024-09-05','2022-12-26',144,21.75,3.27,5.97,12.5,15.04,27.47,57.49,5,12.08,'Screen 16',18.54,NOW(),NOW()),
('742dc02e-3735-4f61-8ab6-33e35915b913','0c3bc855-8f53-40c7-a06c-625bf253f7ae','2024-2025','2019-05-21',65,145,'none','never','organic','never','2024-01-25','2023-01-30',12,FALSE,NULL,5.65,24.26,264.43,75.01,'2025-02-16','2025-02-17','2025-12-15','2025-12-09','2024-01-01',147,21.75,2.04,4.77,14.94,9.39,21.94,68.67,41,12.11,'Screen 18',20.34,NOW(),NOW()),
('28e08569-215b-4ae6-9ce4-ae230ffd6f78','932e5e93-5ff6-4934-9a52-5bb684843628','2023-2024','2022-08-31',14,42,'organic','never','organic','never','2024-12-04','2023-11-10',13,FALSE,NULL,5.92,19.76,208.08,79.36,'2024-02-02','2024-01-31','2024-10-15','2024-10-26','2024-11-10',44,7.94,1.17,1.97,4.8,14.72,24.83,60.45,21,12.71,'Screen 16',7.28,NOW(),NOW()),
('ce0470f2-e760-4eff-bce5-b395633d266d','932e5e93-5ff6-4934-9a52-5bb684843628','2024-2025','2022-08-31',26,42,'organic','never','organic','never','2023-11-10','2021-12-20',23,FALSE,NULL,5.37,20.42,211.27,83.99,'2025-02-04','2025-01-31','2025-12-15','2026-01-04',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,36,13.13,'Screen 16',16.09,NOW(),NOW()),
('7a818b57-2f9c-4d40-b373-9c9177a965df','95011c83-de4a-4da0-a21b-e6ac6a05e966','2021-2022','2018-11-22',35,152,'non-organic','often','both','sometimes','2020-06-14','2019-07-20',11,TRUE,'Coconut',6.6,20.3,126.23,79.07,'2022-01-10','2022-01-18','2022-11-15','2022-12-06',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,24,11.98,'Screen 16',68.15,NOW(),NOW()),
('ce6a68f3-bfc1-4b76-b02e-99237a2e25ed','95011c83-de4a-4da0-a21b-e6ac6a05e966','2022-2023','2018-11-22',47,152,'non-organic','often','both','often','2022-01-29','2021-03-05',11,TRUE,'Ipil-ipil',5.95,23.16,152.08,80.7,'2023-02-06','2023-02-02','2023-12-15','2023-12-06','2021-12-28',155,88.85,13.13,24.26,51.46,14.78,27.3,57.92,10,12.15,'Screen 16',88.08,NOW(),NOW()),
('d196e9cb-c9f9-40af-8fb9-f781dad1d40e','95011c83-de4a-4da0-a21b-e6ac6a05e966','2023-2024','2018-11-22',59,152,'non-organic','often','both','often','2022-11-15','2021-12-20',11,TRUE,'Ipil-ipil',5.98,22.51,206.87,80.7,'2024-01-07','2024-01-12','2024-09-15','2024-09-17','2022-10-16',152,148.56,19.18,30.69,98.69,12.91,20.66,66.43,8,12.24,'Screen 18',142.72,NOW(),NOW()),
('243898ba-f216-4cd3-ad0b-6411a9318559','95011c83-de4a-4da0-a21b-e6ac6a05e966','2024-2025','2018-11-22',71,152,'non-organic','often','both','often','2023-12-28','2022-12-03',13,TRUE,'Banana',6.62,19.53,181.94,77.83,'2024-12-08','2024-12-14','2025-09-15','2025-09-11','2023-11-30',152,63.74,9.11,18.82,35.82,14.29,29.52,56.19,32,12.34,'Screen 15',69.08,NOW(),NOW()),
('e0683f56-7961-4118-a11f-3f2dd6c2b8ee','98b02818-83c0-49ac-81e7-14d66df5165f','2021-2022','2014-09-18',85,73,'organic','rarely','organic','rarely','2015-11-25','2014-06-03',18,FALSE,NULL,5.7,19.92,163.89,80.44,'2022-02-07','2022-02-12','2022-10-15','2022-10-17',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,26,11.56,'Screen 15',25.27,NOW(),NOW()),
('33574a6c-f452-4460-a673-ec35f4128c1d','98b02818-83c0-49ac-81e7-14d66df5165f','2022-2023','2014-09-18',97,73,'organic','rarely','organic','never','2021-12-31','2020-07-09',18,FALSE,NULL,6.79,19.19,197.49,76.09,'2022-12-24','2023-01-02','2023-10-15','2023-10-28','2021-11-27',74,21.07,2.61,6.34,12.12,12.4,30.09,57.51,3,11.08,'Screen 16',21.93,NOW(),NOW()),
('90f9bb31-554b-4d0a-8eb4-a3173ec7a92b','98b02818-83c0-49ac-81e7-14d66df5165f','2023-2024','2014-09-18',109,73,'organic','rarely','organic','never','2022-12-12','2021-10-18',14,FALSE,NULL,6.62,21.71,147.44,78.83,'2023-12-12','2023-12-13','2024-10-15','2024-10-16','2022-11-12',75,13.66,2.13,4.47,7.06,15.59,32.74,51.67,11,12.51,'Screen 18',16.27,NOW(),NOW()),
('677f77dc-784d-4cae-b4c2-f6a6a54a4474','98b02818-83c0-49ac-81e7-14d66df5165f','2024-2025','2014-09-18',121,73,'organic','rarely','organic','rarely','2024-02-05','2022-09-13',17,FALSE,NULL,6.49,23.92,297.12,83.08,'2024-12-06','2024-12-11','2025-09-15','2025-09-16','2024-01-01',72,17.51,1.18,4.8,11.54,6.73,27.39,65.88,14,12.34,'Screen 18',20.23,NOW(),NOW()),
('fdc3d7b5-0b5b-4493-bf03-81eecb5c7b6a','6255ae6a-e4b1-4317-8521-cdca637c10ca','2021-2022','2018-07-22',39,28,'organic','rarely','organic','rarely','2019-11-01','2017-11-11',24,FALSE,NULL,5.63,21.35,257.17,83.94,'2022-02-07','2022-02-14','2022-11-15','2022-11-18',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,36,13.11,'Screen 17',13.32,NOW(),NOW()),
('b945379f-c744-4d81-961d-d180abe54c15','6255ae6a-e4b1-4317-8521-cdca637c10ca','2022-2023','2018-07-22',51,28,'organic','rarely','organic','never','2021-12-24','2020-05-03',20,FALSE,NULL,5.57,24.61,165.56,86.05,'2023-01-02','2022-12-31','2023-11-15','2023-11-28','2021-11-23',27,9.73,0.7,2.37,6.66,7.21,24.33,68.46,31,11.69,'Screen 15',9.58,NOW(),NOW()),
('197927e4-bc47-4eb8-bcfe-24de6fcda9d0','6255ae6a-e4b1-4317-8521-cdca637c10ca','2023-2024','2018-07-22',63,28,'organic','rarely','organic','rarely','2022-11-12','2021-12-17',11,FALSE,NULL,5.99,22.95,125.52,84.91,'2024-02-24','2024-02-25','2024-11-15','2024-11-28','2022-10-18',25,9.22,0.62,2.75,5.85,6.7,29.84,63.46,41,12.9,'Screen 17',9.98,NOW(),NOW()),
('57bfa5c3-2b46-41dc-abb6-45fa8fce80d6','6255ae6a-e4b1-4317-8521-cdca637c10ca','2024-2025','2018-07-22',75,28,'organic','rarely','organic','rarely','2023-12-04','2022-05-13',19,FALSE,NULL,6.18,22.03,234.39,78.46,'2025-02-05','2025-02-06','2025-11-15','2025-11-25','2023-11-02',30,6.0,0.72,2.13,3.15,12.06,35.48,52.46,31,11.38,'Screen 17',5.95,NOW(),NOW()),
('240eba6f-0dc4-4813-aee6-8490570b5bb4','31dcdda1-7f23-4925-94e0-0d59983ec737','2021-2022','2008-01-04',165,89,'non-organic','sometimes','non-organic','rarely','2009-04-20','2007-05-31',23,TRUE,'Mahogany',5.89,23.38,226.98,78.42,'2022-02-07','2022-02-17','2022-12-15','2022-12-11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25,11.63,'Screen 17',30.86,NOW(),NOW()),
('708860b9-916a-4c37-8953-3123f4381c3a','31dcdda1-7f23-4925-94e0-0d59983ec737','2022-2023','2008-01-04',177,89,'non-organic','sometimes','non-organic','sometimes','2022-01-14','2020-08-22',17,TRUE,'Falcata',6.81,23.51,171.5,74.43,'2023-02-28','2023-02-25','2023-11-15','2023-11-27','2021-12-20',91,47.46,6.55,12.39,28.52,13.8,26.11,60.09,22,12.37,'Screen 18',48.55,NOW(),NOW()),
('a5187a7a-d538-4664-99a0-78c373f4073a','31dcdda1-7f23-4925-94e0-0d59983ec737','2023-2024','2008-01-04',189,89,'non-organic','sometimes','non-organic','sometimes','2023-01-24','2022-03-30',10,TRUE,'Coconut',6.3,24.15,264.59,84.17,'2023-12-06','2023-12-15','2024-08-15','2024-09-05','2022-12-24',87,28.15,1.61,8.03,18.51,5.73,28.53,65.74,37,11.24,'Screen 16',31.82,NOW(),NOW()),
('e6de4089-3505-47c7-aaa7-a29dac49b607','31dcdda1-7f23-4925-94e0-0d59983ec737','2024-2025','2008-01-04',201,89,'non-organic','sometimes','non-organic','rarely','2023-12-23','2021-11-03',26,TRUE,'Madre de Cacao',5.54,21.7,274.73,79.55,'2025-01-15','2025-01-18','2025-09-15','2025-09-18','2023-11-23',92,48.99,4.76,17.01,27.22,9.72,34.72,55.56,30,11.98,'Screen 16',46.35,NOW(),NOW()),
('3dd68591-4052-48ad-a99d-3e31f6131898','f2ee69ce-b8c3-44c3-937f-8024282f34a6','2021-2022','2009-09-26',145,87,'non-organic','sometimes','non-organic','rarely','2011-02-12','2009-06-22',20,TRUE,'Coconut',5.65,21.2,219.42,76.21,'2022-02-05','2022-02-06','2022-10-15','2022-10-27',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,19,12.07,'Screen 18',28.81,NOW(),NOW()),
('4156af10-ae04-46cb-847f-a67b8fe308f7','f2ee69ce-b8c3-44c3-937f-8024282f34a6','2022-2023','2009-09-26',157,87,'non-organic','sometimes','non-organic','rarely','2022-02-11','2021-04-17',10,TRUE,'Madre de Cacao',5.1,23.86,248.19,78.98,'2023-01-10','2023-01-17','2023-10-15','2023-11-04','2022-01-07',89,36.58,4.0,7.39,25.19,10.94,20.2,68.86,29,12.55,'Screen 16',37.34,NOW(),NOW()),
('2344de45-fb9e-40a3-a4fb-d14e86134229','f2ee69ce-b8c3-44c3-937f-8024282f34a6','2023-2024','2009-09-26',169,87,'non-organic','sometimes','non-organic','rarely','2023-01-28','2022-04-03',10,TRUE,'Madre de Cacao',6.22,21.53,234.65,82.92,'2024-01-05','2023-12-31','2024-10-15','2024-10-02','2022-12-31',84,39.24,5.27,11.57,22.4,13.42,29.49,57.09,26,11.28,'Screen 18',35.85,NOW(),NOW()),
('09b05873-cb8f-4727-a3cb-abdfcc59aa90','f2ee69ce-b8c3-44c3-937f-8024282f34a6','2024-2025','2009-09-26',181,87,'non-organic','sometimes','non-organic','rarely','2023-12-01','2022-08-08',16,TRUE,'Madre de Cacao',5.71,21.81,197.94,84.07,'2025-01-09','2025-01-06','2025-10-15','2025-10-02','2023-11-05',89,27.34,4.03,6.41,16.9,14.73,23.44,61.83,23,13.48,'Screen 17',25.38,NOW(),NOW()),
('50187cc5-7e9d-49df-96d2-97165fb2737c','e9fa3a05-8e19-4c64-9f15-8940e4be321d','2021-2022','2009-07-16',147,165,'both','often','both','often','2010-11-19','2009-07-27',16,TRUE,'Banana',5.92,23.73,228.73,77.53,'2021-12-19','2021-12-20','2022-09-15','2022-09-17',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,27,11.37,'Screen 15',113.67,NOW(),NOW()),
('483742a5-3cfc-4df5-a784-6a26915575f2','e9fa3a05-8e19-4c64-9f15-8940e4be321d','2022-2023','2009-07-16',159,165,'both','often','both','often','2021-11-07','2021-01-11',10,TRUE,'Mahogany',5.82,24.49,223.4,84.57,'2023-02-07','2023-02-04','2023-12-15','2023-12-16','2021-10-16',162,134.37,9.49,53.21,71.67,7.06,39.6,53.34,24,11.66,'Screen 15',151.66,NOW(),NOW()),
('6c5f9e83-2de2-40d9-bc9b-c35a786704b5','e9fa3a05-8e19-4c64-9f15-8940e4be321d','2023-2024','2009-07-16',171,165,'both','often','both','often','2022-12-05','2021-01-14',23,TRUE,'Mahogany',5.15,22.71,155.23,81.28,'2024-01-27','2024-02-06','2024-09-15','2024-09-28','2022-11-06',164,224.59,21.47,65.24,137.88,9.56,29.05,61.39,21,12.62,'Screen 16',225.13,NOW(),NOW()),
('ef96ab21-5dc0-43e8-967d-ffd9c03f96b1','e9fa3a05-8e19-4c64-9f15-8940e4be321d','2024-2025','2009-07-16',183,165,'both','often','both','sometimes','2024-01-11','2021-12-22',25,TRUE,'Ipil-ipil',5.76,21.86,258.08,80.78,'2024-12-27','2024-12-24','2025-09-15','2025-09-29','2023-12-09',163,93.24,4.32,25.73,63.19,4.63,27.6,67.77,26,12.11,'Screen 18',90.23,NOW(),NOW()),
('a2b5ccab-0fbe-4637-95cc-68208ea91333','d9a44d1d-dea9-4c8d-b180-022d7b46b9d1','2023-2024','2022-09-11',13,155,'organic','rarely','non-organic','never','2024-11-12','2023-07-21',16,TRUE,'Coconut',6.06,21.37,188.19,77.98,'2024-01-18','2024-01-13','2024-11-15','2024-11-13','2024-10-15',152,59.66,9.17,16.19,34.3,15.37,27.13,57.5,15,11.85,'Screen 16',65.13,NOW(),NOW()),
('a4127c68-6644-49eb-9d77-329156f23129','d9a44d1d-dea9-4c8d-b180-022d7b46b9d1','2024-2025','2022-09-11',25,155,'organic','rarely','non-organic','never','2023-09-19','2022-09-24',12,TRUE,'Madre de Cacao',6.14,21.07,205.32,77.58,'2025-01-16','2025-01-22','2025-10-15','2025-11-05',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,18,12.34,'Screen 17',70.26,NOW(),NOW()),
('e832b6aa-c77e-467b-87f1-f2ef8c24a274','aaf5477b-af8a-4a75-af30-f9515ef9a857','2023-2024','2022-04-29',18,154,'organic','rarely','non-organic','rarely','2024-11-19','2023-07-28',16,FALSE,NULL,6.17,21.18,244.79,85.49,'2023-12-07','2023-12-17','2024-09-15','2024-10-04','2024-10-18',155,62.97,7.3,11.44,44.23,11.6,18.16,70.24,17,11.17,'Screen 16',60.05,NOW(),NOW()),
('ef0a5b6f-371a-41a7-b508-5b3b83ceefee','aaf5477b-af8a-4a75-af30-f9515ef9a857','2024-2025','2022-04-29',30,154,'organic','rarely','non-organic','never','2023-07-29','2022-01-05',19,FALSE,NULL,6.76,18.67,218.76,77.93,'2025-02-10','2025-02-09','2025-12-15','2026-01-01',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,10,10.73,'Screen 17',82.34,NOW(),NOW()),
('04dde030-b8bc-4651-b061-339bcfd5e5dd','d5b78ba3-f094-4150-8cfb-e79b8e05331a','2021-2022','2017-11-17',47,213,'non-organic','sometimes','non-organic','rarely','2018-12-13','2017-06-21',18,TRUE,'Coconut',5.85,24.63,212.81,83.23,'2021-12-19','2021-12-15','2022-08-15','2022-08-10',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,32,13.02,'Screen 15',169.75,NOW(),NOW()),
('13f09d3c-fe9c-4bf6-bf65-8ae41f3c7ff9','d5b78ba3-f094-4150-8cfb-e79b8e05331a','2022-2023','2017-11-17',59,213,'non-organic','sometimes','non-organic','sometimes','2022-02-16','2020-03-28',23,TRUE,'Ipil-ipil',5.98,22.45,252.15,77.37,'2023-01-15','2023-01-19','2023-11-15','2023-11-28','2022-01-14',212,106.33,16.95,24.39,64.99,15.94,22.94,61.12,23,11.02,'Screen 15',125.65,NOW(),NOW()),
('be8b07f8-689b-4e49-963f-f4fceaf50da6','d5b78ba3-f094-4150-8cfb-e79b8e05331a','2023-2024','2017-11-17',71,213,'non-organic','sometimes','non-organic','sometimes','2023-02-07','2021-08-16',18,TRUE,'Falcata',5.37,22.7,173.17,76.72,'2023-12-14','2023-12-23','2024-10-15','2024-10-31','2023-01-14',212,65.56,8.65,17.63,39.28,13.2,26.89,59.91,5,11.64,'Screen 17',71.86,NOW(),NOW()),
('eb3eeed6-9b28-46b3-aa6b-33a9d7e5ceed','d5b78ba3-f094-4150-8cfb-e79b8e05331a','2024-2025','2017-11-17',83,213,'non-organic','sometimes','non-organic','rarely','2024-01-19','2022-08-27',17,TRUE,'Banana',6.14,24.44,251.68,81.07,'2024-12-14','2024-12-12','2025-10-15','2025-10-15','2023-12-19',215,127.61,16.07,26.24,85.31,12.59,20.56,66.85,11,11.59,'Screen 16',111.66,NOW(),NOW()),
('4785a34c-0b44-416e-a55d-cc2cfb89e6b9','d854e252-4b42-43a9-95a4-562341d83c82','2021-2022','2011-09-21',121,177,'organic','never','organic','never','2013-07-21','2011-12-29',19,FALSE,NULL,5.85,21.75,211.89,78.24,'2022-01-17','2022-01-27','2022-10-15','2022-10-06',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,29,12.79,'Screen 17',106.53,NOW(),NOW()),
('3ba62b5c-11ae-4708-b40f-e43589a6694d','d854e252-4b42-43a9-95a4-562341d83c82','2022-2023','2011-09-21',133,177,'organic','never','organic','never','2022-01-28','2020-09-05',17,FALSE,NULL,6.67,24.9,259.93,80.63,'2023-02-27','2023-03-02','2023-12-15','2023-12-03','2022-01-06',180,30.1,2.53,11.24,16.33,8.41,37.35,54.24,33,11.96,'Screen 18',35.24,NOW(),NOW()),
('f1ee7f8f-a804-47ca-97b1-146827351a4d','d854e252-4b42-43a9-95a4-562341d83c82','2023-2024','2011-09-21',145,177,'organic','never','organic','never','2022-11-26','2021-01-05',23,FALSE,NULL,5.79,22.58,214.25,75.42,'2024-01-11','2024-01-09','2024-09-15','2024-09-22','2022-10-27',177,37.11,5.57,7.21,24.33,15.0,19.44,65.56,31,11.64,'Screen 18',42.11,NOW(),NOW()),
('d0e6dec5-fc2b-43f2-b7e5-1242225938bd','d854e252-4b42-43a9-95a4-562341d83c82','2024-2025','2011-09-21',157,177,'organic','never','organic','never','2023-12-05','2022-12-10',12,FALSE,NULL,5.85,21.17,196.28,86.05,'2025-02-27','2025-02-22','2025-12-15','2026-01-04','2023-11-07',177,37.65,2.7,8.4,26.55,7.16,22.32,70.52,24,11.42,'Screen 17',40.21,NOW(),NOW()),
('5298b8fa-90a0-4368-b016-5cfce11c0cae','22e9c997-c743-4c3d-972c-5b00f71b83bb','2023-2024','2022-09-13',13,226,'both','often','both','sometimes','2024-11-15','2023-05-25',18,TRUE,'Banana',6.19,22.2,280.11,79.49,'2023-12-01','2023-12-03','2024-10-15','2024-10-11','2024-10-22',225,189.01,28.84,56.51,103.65,15.26,29.9,54.84,19,12.08,'Screen 15',175.52,NOW(),NOW()),
('f1de5c00-0661-45a3-9b21-e2a14d5fecc5','22e9c997-c743-4c3d-972c-5b00f71b83bb','2024-2025','2022-09-13',25,226,'both','often','both','often','2023-11-12','2022-09-18',14,TRUE,'Madre de Cacao',5.7,21.99,241.04,80.07,'2025-01-16','2025-01-18','2025-10-15','2025-11-05',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,7,11.43,'Screen 16',165.44,NOW(),NOW()),
('a2dd6645-f127-40f7-9e01-516aa8686c5b','93ef4210-a5f3-435a-b7b4-cd60cfdf75e7','2021-2022','2014-03-13',91,132,'organic','rarely','organic','never','2015-09-03','2013-07-15',26,FALSE,NULL,6.4,20.92,126.8,82.08,'2022-02-22','2022-03-04','2022-10-15','2022-10-29',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25,11.75,'Screen 18',69.65,NOW(),NOW()),
('0e6f41ab-7c2a-4840-a132-85a1e1f9ec47','93ef4210-a5f3-435a-b7b4-cd60cfdf75e7','2022-2023','2014-03-13',103,132,'organic','rarely','organic','never','2022-01-31','2020-10-08',16,FALSE,NULL,6.44,25.22,185.56,79.0,'2023-01-02','2023-01-07','2023-11-15','2023-12-01','2021-12-28',134,51.66,5.73,16.53,29.4,11.09,31.99,56.92,39,11.81,'Screen 16',52.87,NOW(),NOW()),
('a191a262-81a4-418e-b406-120f7a9717a2','93ef4210-a5f3-435a-b7b4-cd60cfdf75e7','2023-2024','2014-03-13',115,132,'organic','rarely','organic','rarely','2022-11-07','2020-09-18',26,FALSE,NULL,6.42,24.95,197.3,75.58,'2023-12-17','2023-12-26','2024-08-15','2024-08-10','2022-10-15',132,22.89,2.23,7.99,12.67,9.76,34.91,55.33,36,13.13,'Screen 15',23.22,NOW(),NOW()),
('f6e6df8d-729f-4cdf-9d2b-f632bb35ed79','93ef4210-a5f3-435a-b7b4-cd60cfdf75e7','2024-2025','2014-03-13',127,132,'organic','rarely','organic','never','2023-12-29','2022-03-09',22,FALSE,NULL,6.44,22.65,262.89,83.65,'2025-01-11','2025-01-21','2025-11-15','2025-11-03','2023-12-03',133,31.8,2.25,9.78,19.77,7.06,30.77,62.17,9,12.21,'Screen 17',38.13,NOW(),NOW()),
('3d8b1664-0111-428b-a1a3-a082bfae0f1b','80fdd0ec-9bb0-4ef6-84b8-58c1fc8012d8','2021-2022','2010-01-10',141,65,'organic','rarely','organic','never','2011-03-01','2010-02-04',13,FALSE,NULL,5.29,21.77,237.95,84.48,'2021-12-10','2021-12-16','2022-09-15','2022-09-28',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,13,12.05,'Screen 16',25.02,NOW(),NOW()),
('33a196a7-0ac4-4594-8058-fcb00b318b03','80fdd0ec-9bb0-4ef6-84b8-58c1fc8012d8','2022-2023','2010-01-10',153,65,'organic','rarely','organic','rarely','2022-02-07','2020-04-18',22,FALSE,NULL,5.51,22.51,185.84,84.66,'2023-01-21','2023-01-24','2023-10-15','2023-10-17','2022-01-08',67,26.97,2.58,9.4,14.99,9.56,34.85,55.59,3,12.56,'Screen 17',29.32,NOW(),NOW()),
('43b9cdf4-7999-4a82-9f9d-3f4c0abac152','80fdd0ec-9bb0-4ef6-84b8-58c1fc8012d8','2023-2024','2010-01-10',165,65,'organic','rarely','organic','rarely','2022-11-05','2020-11-15',24,FALSE,NULL,6.71,24.68,303.52,78.19,'2024-02-09','2024-02-18','2024-11-15','2024-11-13','2022-10-14',65,19.36,2.58,3.89,12.89,13.32,20.11,66.57,36,11.19,'Screen 18',20.33,NOW(),NOW()),
('9aacab8c-4304-4615-809c-3bbc8774ee2e','80fdd0ec-9bb0-4ef6-84b8-58c1fc8012d8','2024-2025','2010-01-10',177,65,'organic','rarely','organic','never','2023-12-12','2022-05-21',19,FALSE,NULL,5.12,18.84,258.85,79.12,'2025-02-25','2025-02-21','2025-12-15','2026-01-01','2023-11-10',68,29.25,3.09,6.9,19.27,10.55,23.58,65.87,38,11.63,'Screen 16',31.08,NOW(),NOW()),
('a1eb3db6-1b82-45e2-8d91-fc90cbbca1b5','28bbdc75-5746-4aa3-b264-d527dd716759','2021-2022','2015-11-26',71,168,'non-organic','sometimes','non-organic','sometimes','2017-03-02','2015-09-09',18,TRUE,'Falcata',6.4,22.79,241.64,81.4,'2022-02-04','2022-01-31','2022-11-15','2022-11-29',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,4,11.78,'Screen 16',57.97,NOW(),NOW()),
('b63cb05b-4e2c-4458-8dc5-079c2fe9bf0e','28bbdc75-5746-4aa3-b264-d527dd716759','2022-2023','2015-11-26',83,168,'non-organic','sometimes','non-organic','rarely','2021-11-19','2019-12-30',23,TRUE,'Mahogany',6.75,20.37,168.77,80.32,'2023-02-17','2023-02-20','2023-10-15','2023-10-17','2021-10-18',171,105.35,15.92,26.81,62.62,15.11,25.45,59.44,40,13.12,'Screen 17',117.08,NOW(),NOW()),
('3f9f2d02-a213-4cc5-b4f6-ecdfde233eb3','28bbdc75-5746-4aa3-b264-d527dd716759','2023-2024','2015-11-26',95,168,'non-organic','sometimes','non-organic','rarely','2022-11-20','2021-11-25',12,TRUE,'Banana',6.22,20.12,292.85,83.77,'2024-01-28','2024-02-03','2024-09-15','2024-09-26','2022-10-23',165,62.38,10.35,15.2,36.84,16.59,24.36,59.05,13,11.25,'Screen 17',67.71,NOW(),NOW()),
('6b7b272b-f145-432d-b067-3760c58ecd71','28bbdc75-5746-4aa3-b264-d527dd716759','2024-2025','2015-11-26',107,168,'non-organic','sometimes','non-organic','rarely','2023-11-22','2022-03-02',21,TRUE,'Ipil-ipil',6.5,19.86,184.88,73.79,'2025-02-11','2025-02-13','2025-12-15','2025-12-05','2023-10-26',170,122.12,14.52,46.21,61.39,11.89,37.84,50.27,32,12.86,'Screen 17',131.55,NOW(),NOW()),
('1bf45122-1d85-43d4-9b69-0dbf75bbcec5','86fa9300-20a7-4346-980e-5cc4a0a83379','2023-2024','2022-03-01',19,166,'none','never','organic','never','2025-01-01','2024-02-06',11,FALSE,NULL,6.5,21.12,214.35,75.53,'2023-12-13','2023-12-22','2024-09-15','2024-10-05','2024-12-11',166,30.15,1.98,10.03,18.14,6.58,33.26,60.16,29,12.39,'Screen 18',32.54,NOW(),NOW()),
('2c185d47-dcc2-45a3-b871-a02291be1c98','86fa9300-20a7-4346-980e-5cc4a0a83379','2024-2025','2022-03-01',31,166,'none','never','organic','never','2024-01-10','2022-02-19',23,FALSE,NULL,5.63,24.6,190.96,81.7,'2025-01-08','2025-01-14','2025-09-15','2025-09-24',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,28,13.18,'Screen 17',54.83,NOW(),NOW()),
('bf054121-b8f6-4f0d-9fca-7e69b6f2b2b1','fea50ed8-b11c-4586-a273-0b58edbee8de','2023-2024','2022-05-22',17,245,'non-organic','sometimes','non-organic','sometimes','2025-01-01','2023-01-12',24,TRUE,'Banana',6.75,19.71,181.79,81.21,'2023-12-26','2023-12-31','2024-08-15','2024-08-09','2024-11-28',248,189.21,16.88,54.11,118.22,8.92,28.6,62.48,22,11.06,'Screen 16',199.66,NOW(),NOW()),
('c2a427e0-5697-4c86-9e50-a8c5c6e15aef','fea50ed8-b11c-4586-a273-0b58edbee8de','2024-2025','2022-05-22',29,245,'non-organic','sometimes','non-organic','sometimes','2023-08-05','2022-10-09',10,TRUE,'Mahogany',5.99,20.98,301.25,86.74,'2024-12-04','2024-11-29','2025-08-15','2025-08-01',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,16,12.52,'Screen 17',75.43,NOW(),NOW()),
('5052a760-0674-4467-88d4-0a0a40cbe15e','589e2f16-9656-4c94-8549-50db17ce2be5','2021-2022','2013-12-13',94,100,'both','often','both','often','2015-07-16','2013-05-27',26,TRUE,'Coconut',5.81,19.91,153.82,79.57,'2022-02-04','2022-02-13','2022-12-15','2022-12-15',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,39,10.94,'Screen 17',52.9,NOW(),NOW()),
('b3f754cc-64b8-4a55-a846-4808394557c0','589e2f16-9656-4c94-8549-50db17ce2be5','2022-2023','2013-12-13',106,100,'both','often','both','often','2022-02-03','2020-04-14',22,TRUE,'Banana',5.89,21.69,164.08,81.93,'2022-12-11','2022-12-10','2023-08-15','2023-08-09','2022-01-06',99,51.08,6.42,15.25,29.41,12.57,29.85,57.58,22,12.13,'Screen 17',50.23,NOW(),NOW()),
('8c4b22dc-c203-4cd2-80ab-c0d6df53c699','589e2f16-9656-4c94-8549-50db17ce2be5','2023-2024','2013-12-13',118,100,'both','often','both','sometimes','2023-02-10','2021-03-22',23,TRUE,'Madre de Cacao',6.12,19.78,239.0,83.66,'2024-02-24','2024-02-25','2024-11-15','2024-11-29','2023-01-12',98,84.7,11.3,27.86,45.54,13.34,32.89,53.77,15,12.62,'Screen 18',84.33,NOW(),NOW()),
('23a7dad5-ebc3-4799-bae5-9064c65f4195','589e2f16-9656-4c94-8549-50db17ce2be5','2024-2025','2013-12-13',130,100,'both','often','both','often','2024-02-12','2022-06-22',20,TRUE,'Mahogany',6.59,22.73,202.08,76.42,'2024-12-03','2024-11-30','2025-08-15','2025-08-28','2024-01-16',97,60.1,8.65,15.8,35.65,14.4,26.29,59.31,27,11.79,'Screen 16',62.79,NOW(),NOW()),
('80199c56-553d-4efb-aff6-5c79387d27aa','d9be44b6-82e3-4fbd-b6e6-db875863b861','2023-2024','2022-10-28',12,216,'organic','rarely','organic','never','2024-11-21','2023-10-28',13,FALSE,NULL,5.87,21.63,267.27,85.25,'2024-02-02','2024-02-06','2024-12-15','2024-12-20','2024-10-21',215,50.39,5.96,8.12,36.31,11.82,16.12,72.06,11,12.01,'Screen 16',54.41,NOW(),NOW()),
('eecd0a51-d5f8-44c0-a497-3e7399b85db0','d9be44b6-82e3-4fbd-b6e6-db875863b861','2024-2025','2022-10-28',24,216,'organic','rarely','organic','rarely','2023-12-22','2022-04-01',21,FALSE,NULL,6.03,23.78,201.34,82.49,'2025-01-28','2025-01-23','2025-11-15','2025-11-18',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,5,11.61,'Screen 17',164.33,NOW(),NOW()),
('2c399144-8589-4053-bded-0c0d5af989f8','5074b97e-3c29-49c0-bfa4-034931344665','2023-2024','2022-06-29',16,43,'both','often','both','often','2025-01-21','2023-11-28',14,TRUE,'Coconut',6.1,22.27,204.94,76.26,'2023-12-03','2023-12-04','2024-09-15','2024-09-27','2024-12-18',43,33.12,5.38,10.44,17.3,16.24,31.53,52.23,12,11.79,'Screen 17',37.16,NOW(),NOW()),
('d977c3d9-28b4-406e-9d95-8698ba638081','5074b97e-3c29-49c0-bfa4-034931344665','2024-2025','2022-06-29',28,43,'both','often','both','often','2023-09-16','2022-06-23',15,TRUE,'Banana',5.89,23.2,149.93,75.23,'2025-01-16','2025-01-25','2025-10-15','2025-10-18',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,8,12.02,'Screen 17',22.14,NOW(),NOW()),
('7a133f3b-ad17-4c04-873a-d5eb44161a40','82eed5d7-d586-49f2-913f-78e555f7ed13','2023-2024','2022-05-26',17,166,'non-organic','sometimes','non-organic','rarely','2025-01-04','2023-06-14',19,TRUE,'Ipil-ipil',5.12,19.21,204.35,80.84,'2024-01-07','2024-01-06','2024-10-15','2024-10-19','2024-12-04',165,75.02,6.23,24.85,43.94,8.31,33.12,58.57,10,12.0,'Screen 18',68.38,NOW(),NOW()),
('e90ce49d-1243-4162-a0c6-2502746bf0eb','82eed5d7-d586-49f2-913f-78e555f7ed13','2024-2025','2022-05-26',29,166,'non-organic','sometimes','non-organic','rarely','2024-05-20','2022-12-27',17,TRUE,'Ipil-ipil',5.36,22.0,259.45,83.02,'2025-02-02','2025-02-10','2025-10-15','2025-10-30',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,38,12.71,'Screen 18',97.39,NOW(),NOW()),
('c55a46e5-c561-4844-aabd-d4325f2a7237','62d7b93f-9ae3-4c18-9a74-3091844c4e33','2021-2022','2017-05-14',53,222,'non-organic','often','both','sometimes','2018-12-07','2018-02-10',10,TRUE,'Banana',5.91,24.96,175.62,85.41,'2022-02-12','2022-02-09','2022-11-15','2022-11-07',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,11,12.14,'Screen 15',110.53,NOW(),NOW()),
('09e27a1c-7d65-43dd-a4a5-cc4975dc13ca','62d7b93f-9ae3-4c18-9a74-3091844c4e33','2022-2023','2017-05-14',65,222,'non-organic','often','both','sometimes','2022-01-29','2020-09-06',17,TRUE,'Falcata',5.45,21.26,175.01,80.08,'2023-02-07','2023-02-13','2023-11-15','2023-11-10','2022-01-03',220,143.65,21.55,41.16,80.95,15.0,28.65,56.35,7,11.57,'Screen 16',152.39,NOW(),NOW()),
('413ae9de-f65c-4ae5-bb14-18447a6cd3b9','62d7b93f-9ae3-4c18-9a74-3091844c4e33','2023-2024','2017-05-14',77,222,'non-organic','often','both','often','2023-01-20','2020-12-31',25,TRUE,'Coconut',6.16,21.85,222.03,80.66,'2024-02-21','2024-02-26','2024-12-15','2024-12-21','2022-12-18',220,172.44,17.4,44.77,110.28,10.09,25.96,63.95,17,11.95,'Screen 17',194.64,NOW(),NOW()),
('4c843f3a-681d-400e-9edd-a80c2a52d73e','62d7b93f-9ae3-4c18-9a74-3091844c4e33','2024-2025','2017-05-14',89,222,'non-organic','often','both','often','2024-01-02','2023-01-07',12,TRUE,'Mahogany',6.39,21.15,210.19,74.7,'2024-12-21','2024-12-18','2025-10-15','2025-11-02','2023-12-04',222,102.43,9.14,24.32,68.98,8.92,23.74,67.34,17,12.08,'Screen 15',103.19,NOW(),NOW()),
('c3803c62-fc6e-4c72-ac3a-1c93776c4dda','1dd73c5f-8111-403e-abd0-41107e938273','2021-2022','2012-03-22',115,79,'organic','rarely','non-organic','never','2013-11-20','2011-10-02',26,TRUE,'Ipil-ipil',6.53,20.2,153.37,75.64,'2022-01-23','2022-01-20','2022-11-15','2022-11-12',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,6,12.35,'Screen 18',44.4,NOW(),NOW()),
('3726a477-9726-47e3-b751-15ad31bf4c66','1dd73c5f-8111-403e-abd0-41107e938273','2022-2023','2012-03-22',127,79,'organic','rarely','non-organic','rarely','2021-12-25','2020-06-03',19,TRUE,'Mahogany',5.31,21.52,249.56,81.59,'2023-02-21','2023-02-26','2023-10-15','2023-10-22','2021-11-29',76,45.19,5.36,11.88,27.95,11.85,26.29,61.86,24,11.82,'Screen 17',49.86,NOW(),NOW()),
('c9c40ae0-040f-4a66-a53c-c35b38fcb89f','1dd73c5f-8111-403e-abd0-41107e938273','2023-2024','2012-03-22',139,79,'organic','rarely','non-organic','rarely','2023-02-03','2021-12-10',14,TRUE,'Mahogany',6.14,24.37,194.73,81.36,'2023-12-20','2023-12-17','2024-09-15','2024-10-06','2023-01-12',79,43.5,6.16,11.8,25.54,14.17,27.12,58.71,27,11.72,'Screen 16',47.18,NOW(),NOW()),
('ca9561cf-54d8-4d02-b535-c210e20a57ad','1dd73c5f-8111-403e-abd0-41107e938273','2024-2025','2012-03-22',151,79,'organic','rarely','non-organic','rarely','2023-11-15','2021-12-25',23,TRUE,'Falcata',6.67,22.03,138.11,78.29,'2025-01-25','2025-02-04','2025-09-15','2025-09-15','2023-10-15',77,21.59,1.91,5.56,14.12,8.84,25.76,65.4,12,11.65,'Screen 15',22.19,NOW(),NOW()),
('e1f5bea7-f5f3-4208-9009-17c38b44938c','f0e659d5-af04-4a13-9b66-75d985f34efb','2023-2024','2022-10-04',12,164,'organic','rarely','non-organic','rarely','2024-12-05','2023-04-15',20,FALSE,NULL,5.53,24.01,228.33,80.82,'2023-12-27','2023-12-27','2024-10-15','2024-10-29','2024-11-04',161,56.92,3.52,14.03,39.37,6.19,24.65,69.16,21,12.29,'Screen 16',67.7,NOW(),NOW()),
('12ebff29-26e4-415e-ab82-083999eb3c6b','f0e659d5-af04-4a13-9b66-75d985f34efb','2024-2025','2022-10-04',24,164,'organic','rarely','non-organic','never','2024-05-20','2022-12-27',17,FALSE,NULL,5.92,22.14,194.64,83.05,'2024-12-12','2024-12-21','2025-09-15','2025-09-19',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,32,12.0,'Screen 18',128.43,NOW(),NOW()),
('c859226e-8628-44e5-bddf-a45ddf4bbc51','3ff6da60-1fa3-4113-94cb-b85fb9fbc66a','2023-2024','2022-04-13',18,80,'organic','rarely','organic','rarely','2024-12-25','2023-07-04',18,FALSE,NULL,6.62,19.29,213.1,78.89,'2024-02-28','2024-02-26','2024-11-15','2024-11-06','2024-11-21',83,12.0,1.26,4.78,5.97,10.48,39.8,49.72,14,11.92,'Screen 16',13.69,NOW(),NOW()),
('207bd18d-89be-4a75-af62-b7ec331c7bed','3ff6da60-1fa3-4113-94cb-b85fb9fbc66a','2024-2025','2022-04-13',30,80,'organic','rarely','organic','rarely','2023-08-04','2021-08-14',24,FALSE,NULL,5.84,24.08,280.89,79.29,'2025-01-08','2025-01-15','2025-09-15','2025-09-24',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,17,11.7,'Screen 15',57.57,NOW(),NOW()),
('741ac179-a157-4951-a636-93bb1de202a1','0b0bf418-c4a6-4215-9430-a0bd47277df7','2021-2022','2015-07-09',75,203,'none','never','none','never','2016-09-16','2015-10-22',11,FALSE,NULL,5.5,21.03,258.8,81.76,'2022-02-16','2022-02-25','2022-12-15','2022-12-01',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,41,10.79,'Screen 16',145.65,NOW(),NOW()),
('d099aa7b-25ce-41ad-aeb6-35e41c688c86','0b0bf418-c4a6-4215-9430-a0bd47277df7','2022-2023','2015-07-09',87,203,'none','never','none','never','2021-12-07','2020-05-16',19,FALSE,NULL,6.11,20.76,166.83,77.52,'2023-02-15','2023-02-12','2023-10-15','2023-11-01','2021-11-15',204,30.45,1.55,5.17,23.73,5.09,16.99,77.92,30,12.21,'Screen 16',33.54,NOW(),NOW()),
('17dd4ff8-2e8d-4c29-a511-e0c3d3522ea1','0b0bf418-c4a6-4215-9430-a0bd47277df7','2023-2024','2015-07-09',99,203,'none','never','none','never','2023-01-17','2022-03-23',10,FALSE,NULL,6.14,22.49,185.8,79.3,'2023-12-17','2023-12-23','2024-08-15','2024-09-03','2022-12-21',204,30.45,1.8,8.27,20.37,5.92,27.17,66.91,29,13.27,'Screen 15',30.04,NOW(),NOW()),
('241fabc6-12b2-47f3-aa9e-8c92ee460ad9','0b0bf418-c4a6-4215-9430-a0bd47277df7','2024-2025','2015-07-09',111,203,'none','never','none','never','2024-02-05','2022-04-16',22,FALSE,NULL,6.32,25.22,187.57,73.44,'2025-01-08','2025-01-06','2025-11-15','2025-11-22','2024-01-15',201,30.45,2.36,7.91,20.18,7.74,25.99,66.27,8,12.07,'Screen 16',34.73,NOW(),NOW()),
('aac5fb2b-2cbe-4152-93ee-b077756f0c0c','163a16ab-b56f-4662-8401-5efe215a4f23','2023-2024','2022-12-17',10,61,'organic','never','organic','never','2025-01-24','2023-01-05',25,FALSE,NULL,6.3,22.57,255.6,74.84,'2024-01-02','2024-01-06','2024-09-15','2024-09-03','2024-12-23',64,9.15,1.14,2.92,5.09,12.48,31.89,55.63,16,10.93,'Screen 17',9.43,NOW(),NOW()),
('fc0978b8-e06a-4c9d-8316-e284fbc70b96','163a16ab-b56f-4662-8401-5efe215a4f23','2024-2025','2022-12-17',22,61,'organic','never','organic','never','2024-04-24','2023-05-30',11,FALSE,NULL,6.31,23.19,178.65,78.76,'2025-02-11','2025-02-14','2025-10-15','2025-10-24',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25,11.84,'Screen 18',45.59,NOW(),NOW()),
('07b38b1a-c23e-4ac7-ac00-c9754aff50b7','6304d717-5d9e-42b6-8c4e-1ddc9b603a09','2023-2024','2022-07-17',15,109,'both','often','both','sometimes','2024-11-18','2022-10-30',25,TRUE,'Coconut',5.39,21.43,253.22,77.84,'2024-01-03','2024-01-11','2024-11-15','2024-11-12','2024-10-21',110,77.02,12.98,26.18,37.86,16.85,33.99,49.16,10,11.18,'Screen 17',83.28,NOW(),NOW()),
('aa167ce9-bbd2-41f9-ac4a-c7a3609f68e4','6304d717-5d9e-42b6-8c4e-1ddc9b603a09','2024-2025','2022-07-17',27,109,'both','often','both','sometimes','2024-05-20','2022-06-30',23,TRUE,'Madre de Cacao',6.22,20.31,209.39,79.57,'2025-01-20','2025-01-28','2025-10-15','2025-10-04',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,4,12.22,'Screen 17',60.66,NOW(),NOW()),
('54c8a3c8-970d-4bc5-875d-834160e59a1d','de144329-9a84-4ee1-8771-b1ff9e54b714','2021-2022','2011-08-03',122,253,'non-organic','sometimes','non-organic','sometimes','2013-06-09','2011-06-20',24,TRUE,'Coconut',5.81,19.06,154.79,82.68,'2022-01-19','2022-01-15','2022-11-15','2022-11-10',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,27,13.02,'Screen 17',132.06,NOW(),NOW()),
('f9115a55-c601-4db2-a760-3f83c621a214','de144329-9a84-4ee1-8771-b1ff9e54b714','2022-2023','2011-08-03',134,253,'non-organic','sometimes','non-organic','sometimes','2021-11-29','2019-10-11',26,TRUE,'Ipil-ipil',6.71,21.43,195.23,77.97,'2022-12-24','2022-12-24','2023-09-15','2023-10-04','2021-11-06',253,149.14,16.94,32.23,99.97,11.36,21.61,67.03,38,11.23,'Screen 17',163.52,NOW(),NOW()),
('21dc7ef7-dc0c-46da-b527-ecef6faf1613','de144329-9a84-4ee1-8771-b1ff9e54b714','2023-2024','2011-08-03',146,253,'non-organic','sometimes','non-organic','sometimes','2023-01-04','2020-12-15',25,TRUE,'Ipil-ipil',5.56,20.53,169.43,75.08,'2024-02-15','2024-02-12','2024-12-15','2024-12-21','2022-12-10',255,102.01,14.41,28.02,59.57,14.13,27.47,58.4,18,11.04,'Screen 17',118.53,NOW(),NOW()),
('a4daa9aa-f294-44ae-8ba4-faee85167f5e','de144329-9a84-4ee1-8771-b1ff9e54b714','2024-2025','2011-08-03',158,253,'non-organic','sometimes','non-organic','sometimes','2023-11-24','2022-08-31',15,TRUE,'Falcata',5.6,23.43,216.04,75.94,'2024-12-08','2024-12-18','2025-08-15','2025-08-24','2023-10-23',254,122.65,12.46,28.66,81.53,10.16,23.37,66.47,24,11.95,'Screen 16',130.52,NOW(),NOW()),
('5ce3052d-22af-4395-867c-9b30b66c7d65','6cac8d82-bb3e-47fc-a172-412d77db327b','2023-2024','2022-02-14',20,187,'organic','rarely','non-organic','rarely','2024-11-28','2022-11-09',25,TRUE,'Mahogany',5.36,22.1,248.74,83.24,'2024-01-21','2024-01-18','2024-10-15','2024-10-30','2024-11-01',189,101.94,11.89,27.3,62.75,11.66,26.78,61.56,23,11.26,'Screen 16',114.04,NOW(),NOW()),
('823664c6-0174-4dce-97fa-86be591fee42','6cac8d82-bb3e-47fc-a172-412d77db327b','2024-2025','2022-02-14',32,187,'organic','rarely','non-organic','rarely','2023-10-29','2022-12-03',11,TRUE,'Madre de Cacao',5.54,23.68,217.04,78.24,'2025-02-08','2025-02-14','2025-12-15','2025-12-19',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,35,11.56,'Screen 17',67.8,NOW(),NOW()),
('a4095d5a-d04d-4533-a87f-d66d3a07552a','258ea41a-b7ef-4ff1-b812-326c1e8b297e','2021-2022','2014-10-16',84,84,'both','often','both','often','2016-09-08','2015-06-16',15,TRUE,'Ipil-ipil',6.09,22.39,223.95,76.68,'2022-02-11','2022-02-07','2022-10-15','2022-10-06',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,4,12.23,'Screen 17',52.55,NOW(),NOW()),
('80e3d4b6-d0f9-40a4-991c-ccc3f5bad01d','258ea41a-b7ef-4ff1-b812-326c1e8b297e','2022-2023','2014-10-16',96,84,'both','often','both','sometimes','2022-02-05','2021-04-11',10,TRUE,'Ipil-ipil',6.69,21.99,229.43,78.09,'2023-01-08','2023-01-15','2023-10-15','2023-10-30','2022-01-05',81,54.05,8.46,17.06,28.52,15.66,31.57,52.77,24,11.34,'Screen 18',55.1,NOW(),NOW()),
('1f56844a-ad3b-4682-ad42-1e9d99db1ffc','258ea41a-b7ef-4ff1-b812-326c1e8b297e','2023-2024','2014-10-16',108,84,'both','often','both','often','2022-12-10','2021-10-16',14,TRUE,'Mahogany',6.45,21.16,241.29,82.17,'2024-01-05','2024-01-11','2024-11-15','2024-12-06','2022-11-10',81,34.92,3.93,9.65,21.34,11.26,27.64,61.1,12,11.95,'Screen 17',35.18,NOW(),NOW()),
('0b24d1ec-3f22-4aaa-8036-655d37b53850','258ea41a-b7ef-4ff1-b812-326c1e8b297e','2024-2025','2014-10-16',120,84,'both','often','both','often','2024-02-05','2022-07-15',19,TRUE,'Banana',6.71,24.68,265.33,79.32,'2024-12-27','2025-01-01','2025-10-15','2025-10-21','2024-01-15',82,56.36,7.76,15.76,32.84,13.76,27.97,58.27,27,12.0,'Screen 18',57.74,NOW(),NOW()),
('e45b6bf4-8f60-419d-9076-8b7978d93456','ca59205f-b5e7-42fb-ab16-ffa5961d6898','2021-2022','2014-12-02',82,116,'non-organic','sometimes','non-organic','rarely','2016-01-17','2014-03-28',22,TRUE,'Banana',5.8,22.02,292.93,77.25,'2021-12-10','2021-12-20','2022-10-15','2022-10-31',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,15,10.69,'Screen 15',59.79,NOW(),NOW()),
('296c965e-126b-44ec-87d2-5ea19a5d997d','ca59205f-b5e7-42fb-ab16-ffa5961d6898','2022-2023','2014-12-02',94,116,'non-organic','sometimes','non-organic','rarely','2021-12-07','2020-02-16',22,TRUE,'Falcata',5.59,21.42,204.91,80.58,'2023-02-10','2023-02-07','2023-11-15','2023-12-03','2021-11-11',116,51.3,7.2,11.56,32.54,14.03,22.54,63.43,30,11.62,'Screen 15',45.92,NOW(),NOW()),
('8f677b89-6d6e-40af-a2cf-a3873275e64c','ca59205f-b5e7-42fb-ab16-ffa5961d6898','2023-2024','2014-12-02',106,116,'non-organic','sometimes','non-organic','sometimes','2022-11-17','2021-03-27',20,TRUE,'Madre de Cacao',6.06,22.24,201.12,76.3,'2024-01-17','2024-01-13','2024-09-15','2024-09-03','2022-10-22',114,71.98,10.08,20.64,41.26,14.01,28.67,57.32,28,12.56,'Screen 18',64.94,NOW(),NOW()),
('85d12c7a-caf5-4d16-bd6e-81183f91f6d4','ca59205f-b5e7-42fb-ab16-ffa5961d6898','2024-2025','2014-12-02',118,116,'non-organic','sometimes','non-organic','sometimes','2023-12-02','2022-04-11',20,TRUE,'Mahogany',5.73,20.28,305.63,82.22,'2025-01-17','2025-01-27','2025-11-15','2025-11-20','2023-10-28',116,52.05,5.34,15.8,30.91,10.26,30.36,59.38,32,11.79,'Screen 15',62.09,NOW(),NOW()),
('e48ef98d-fa00-4795-91b1-3bdfa834c30b','dea8cd83-49a4-4dc2-9218-84c02c4f2336','2021-2022','2014-11-25',83,81,'both','often','both','often','2016-07-24','2015-01-31',18,TRUE,'Ipil-ipil',6.04,24.97,250.89,82.65,'2022-02-02','2022-02-12','2022-10-15','2022-11-03',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,21,12.19,'Screen 18',30.28,NOW(),NOW()),
('511bb518-8404-48d4-a6a4-1fcabe40db13','dea8cd83-49a4-4dc2-9218-84c02c4f2336','2022-2023','2014-11-25',95,81,'both','often','both','often','2021-11-20','2020-10-26',13,TRUE,'Banana',5.86,20.47,209.1,79.32,'2022-12-14','2022-12-24','2023-10-15','2023-10-04','2021-10-21',83,41.19,5.6,11.09,24.5,13.59,26.93,59.48,6,11.47,'Screen 17',49.4,NOW(),NOW()),
('4e11e379-72d4-48d6-86bb-0e819b3bf145','dea8cd83-49a4-4dc2-9218-84c02c4f2336','2023-2024','2014-11-25',107,81,'both','often','both','sometimes','2023-01-18','2021-05-28',20,TRUE,'Ipil-ipil',6.0,24.82,210.97,80.27,'2024-02-25','2024-02-28','2024-12-15','2024-12-31','2022-12-22',79,39.99,3.02,11.73,25.24,7.54,29.34,63.12,40,11.62,'Screen 17',37.14,NOW(),NOW()),
('efbee9b5-35b6-4f3c-bdac-1ce40fd74dc8','dea8cd83-49a4-4dc2-9218-84c02c4f2336','2024-2025','2014-11-25',119,81,'both','often','both','sometimes','2023-12-14','2022-08-21',16,TRUE,'Mahogany',6.02,22.85,213.97,79.84,'2025-02-09','2025-02-13','2025-10-15','2025-11-04','2023-11-12',81,39.75,5.72,10.44,23.58,14.4,26.27,59.33,34,11.83,'Screen 17',47.07,NOW(),NOW()),
('bfe48b67-d0cb-429d-a52f-b118ea49b534','4ce4fd5a-374a-4ee3-8019-5043952959ff','2021-2022','2011-04-14',126,240,'organic','rarely','organic','never','2012-05-04','2010-10-12',19,FALSE,NULL,6.13,24.8,157.72,84.88,'2022-02-16','2022-02-17','2022-10-15','2022-11-04',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,18,12.1,'Screen 17',88.47,NOW(),NOW()),
('ea851a32-bfff-4aed-98f5-a491fe471eb7','4ce4fd5a-374a-4ee3-8019-5043952959ff','2022-2023','2011-04-14',138,240,'organic','rarely','organic','rarely','2022-01-19','2021-02-23',11,FALSE,NULL,5.31,22.75,218.43,81.19,'2023-01-11','2023-01-21','2023-09-15','2023-09-09','2021-12-26',237,54.72,6.21,13.69,34.82,11.34,25.02,63.64,43,13.18,'Screen 16',54.31,NOW(),NOW()),
('49b3a510-42c1-4045-bdb2-f72d76e60f52','4ce4fd5a-374a-4ee3-8019-5043952959ff','2023-2024','2011-04-14',150,240,'organic','rarely','organic','never','2022-12-04','2021-08-11',16,FALSE,NULL,5.33,23.21,191.91,78.04,'2023-12-21','2023-12-23','2024-10-15','2024-10-03','2022-11-06',238,100.58,15.71,22.08,62.79,15.62,21.95,62.43,22,12.65,'Screen 15',120.6,NOW(),NOW()),
('15d490f4-a313-4726-87dc-a2bda8f5b0c4','4ce4fd5a-374a-4ee3-8019-5043952959ff','2024-2025','2011-04-14',162,240,'organic','rarely','organic','never','2024-01-05','2021-12-16',25,FALSE,NULL,5.72,20.44,245.69,83.96,'2024-12-01','2024-12-05','2025-10-15','2025-10-07','2023-12-03',239,44.6,4.93,9.38,30.29,11.05,21.03,67.92,18,13.28,'Screen 18',51.79,NOW(),NOW()),
('93dd48d1-d04a-4c09-9dc4-fe824e7d563d','a12d98ec-7714-4151-bc79-381deea83e33','2021-2022','2011-01-04',129,166,'organic','never','organic','never','2012-05-22','2011-01-28',16,FALSE,NULL,6.12,23.53,197.15,82.13,'2022-02-06','2022-02-01','2022-12-15','2022-12-22',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,35,12.11,'Screen 16',64.37,NOW(),NOW()),
('65534a4e-1492-42e1-9803-7cf10dc2a99a','a12d98ec-7714-4151-bc79-381deea83e33','2022-2023','2011-01-04',141,166,'organic','never','organic','never','2022-02-01','2020-03-13',23,FALSE,NULL,5.58,22.06,159.51,81.49,'2022-12-16','2022-12-21','2023-08-15','2023-08-01','2021-12-29',165,24.9,2.02,7.59,15.29,8.12,30.47,61.41,23,11.92,'Screen 17',29.48,NOW(),NOW()),
('dc309644-0dd7-4f97-89d7-d62283a71fad','a12d98ec-7714-4151-bc79-381deea83e33','2023-2024','2011-01-04',153,166,'organic','never','organic','never','2022-12-13','2022-02-16',10,FALSE,NULL,6.15,20.89,200.45,77.5,'2024-01-10','2024-01-10','2024-10-15','2024-11-02','2022-11-13',168,32.14,3.29,8.88,19.97,10.25,27.62,62.13,34,12.32,'Screen 17',31.45,NOW(),NOW()),
('bc3b5e0c-e705-4055-bcb0-d465a7ab62da','a12d98ec-7714-4151-bc79-381deea83e33','2024-2025','2011-01-04',165,166,'organic','never','organic','never','2024-01-16','2022-11-22',14,FALSE,NULL,5.82,21.91,210.5,86.8,'2025-02-18','2025-02-28','2025-12-15','2025-12-14','2023-12-23',169,24.9,2.1,7.36,15.44,8.45,29.55,62.0,18,12.45,'Screen 15',25.74,NOW(),NOW()),
('40396aef-6776-464b-974c-16e248ac2d2e','0274bf00-1a00-40e6-a257-59fa64fa9ac2','2021-2022','2019-11-05',23,190,'both','often','both','sometimes','2021-08-19','2020-07-25',13,TRUE,'Banana',6.03,19.41,220.24,80.04,'2021-12-06','2021-12-11','2022-10-15','2022-10-29',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,6,11.46,'Screen 18',65.64,NOW(),NOW()),
('bb36f4de-e262-4244-893f-6c00b255d9aa','0274bf00-1a00-40e6-a257-59fa64fa9ac2','2022-2023','2019-11-05',35,190,'both','often','both','sometimes','2021-12-23','2020-10-29',14,TRUE,'Banana',5.91,22.05,210.68,74.72,'2023-01-24','2023-01-19','2023-10-15','2023-10-17','2021-11-25',193,78.47,5.26,22.1,51.11,6.7,28.17,65.13,1,11.49,'Screen 15',67.94,NOW(),NOW()),
('575dd0e9-e3cd-4ef0-aa4a-d41c1d537f2b','0274bf00-1a00-40e6-a257-59fa64fa9ac2','2023-2024','2019-11-05',47,190,'both','often','both','sometimes','2023-01-15','2022-02-19',11,TRUE,'Falcata',5.24,24.55,155.25,85.09,'2024-01-06','2024-01-05','2024-11-15','2024-11-27','2022-12-24',189,109.6,16.55,37.71,55.34,15.1,34.41,50.49,46,11.81,'Screen 18',107.57,NOW(),NOW()),
('07f760a7-d10c-4aa4-bdd2-3e96a343d0ee','0274bf00-1a00-40e6-a257-59fa64fa9ac2','2024-2025','2019-11-05',59,190,'both','often','both','often','2024-02-19','2022-05-30',21,TRUE,'Falcata',5.48,19.95,307.46,79.09,'2024-12-27','2024-12-22','2025-08-15','2025-08-20','2024-01-16',190,199.6,22.0,37.96,139.64,11.02,19.02,69.96,23,12.07,'Screen 18',227.18,NOW(),NOW()),
('a38611e4-5a9b-4d35-827c-4bf344bb6bc1','9c565b1c-51d3-4cd3-b206-6712f115bf66','2023-2024','2022-05-07',17,122,'none','never','organic','never','2024-12-24','2023-10-31',14,FALSE,NULL,5.45,20.97,282.89,82.07,'2024-02-14','2024-02-09','2024-10-15','2024-10-14','2024-11-28',119,18.3,1.75,5.06,11.49,9.57,27.65,62.78,12,10.89,'Screen 15',17.12,NOW(),NOW()),
('6cb705b8-42b8-41d5-8ba6-6233506a5f7c','9c565b1c-51d3-4cd3-b206-6712f115bf66','2024-2025','2022-05-07',29,122,'none','never','organic','never','2023-11-28','2021-12-08',24,FALSE,NULL,5.32,20.74,182.54,83.82,'2025-02-10','2025-02-12','2025-12-15','2025-12-21',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,29,12.49,'Screen 17',51.05,NOW(),NOW()),
('331019ab-1473-40bf-b5bf-bbda57bf4c90','80d74c12-eba9-42a8-842c-6f289b6eb41d','2021-2022','2011-03-19',127,47,'non-organic','often','both','often','2012-08-18','2011-02-25',18,TRUE,'Madre de Cacao',6.56,19.4,286.35,84.08,'2022-02-22','2022-03-02','2022-12-15','2023-01-01',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,5,11.74,'Screen 18',32.57,NOW(),NOW()),
('694cd538-28e5-4269-9bc2-fbb1524d0b3a','80d74c12-eba9-42a8-842c-6f289b6eb41d','2022-2023','2011-03-19',139,47,'non-organic','often','both','sometimes','2022-01-01','2020-02-11',23,TRUE,'Falcata',5.92,20.19,202.32,82.39,'2022-12-10','2022-12-09','2023-09-15','2023-09-04','2021-12-05',48,31.47,3.5,8.13,19.84,11.12,25.83,63.05,16,11.87,'Screen 16',31.03,NOW(),NOW()),
('a375d3fc-9cc4-42bd-babe-89356605396c','80d74c12-eba9-42a8-842c-6f289b6eb41d','2023-2024','2011-03-19',151,47,'non-organic','often','both','sometimes','2022-11-11','2021-11-16',12,TRUE,'Coconut',6.22,24.42,262.01,75.44,'2023-12-02','2023-12-05','2024-09-15','2024-09-03','2022-10-16',50,17.93,2.84,5.01,10.08,15.86,27.94,56.2,6,12.56,'Screen 16',18.25,NOW(),NOW()),
('debb9bd4-303e-4c82-ba6f-551653ca96cd','80d74c12-eba9-42a8-842c-6f289b6eb41d','2024-2025','2011-03-19',163,47,'non-organic','often','both','sometimes','2023-12-12','2023-02-15',10,TRUE,'Mahogany',6.25,20.6,178.48,82.25,'2025-01-08','2025-01-09','2025-10-15','2025-10-16','2023-11-07',48,34.13,4.79,10.94,18.4,14.04,32.06,53.9,13,11.63,'Screen 18',35.39,NOW(),NOW()),
('93ddcbe8-5b9e-446e-bb2e-d7a4a9a42eb7','a7b8fac6-1745-416f-8eed-a4426de4f0b1','2021-2022','2016-01-22',69,185,'non-organic','sometimes','non-organic','rarely','2017-07-24','2015-06-05',26,TRUE,'Mahogany',6.22,24.06,211.61,82.98,'2022-01-07','2022-01-13','2022-10-15','2022-10-27',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,6,12.72,'Screen 16',57.0,NOW(),NOW()),
('d1eadc88-a015-4653-a143-6593df520d0c','a7b8fac6-1745-416f-8eed-a4426de4f0b1','2022-2023','2016-01-22',81,185,'non-organic','sometimes','non-organic','rarely','2022-01-16','2020-09-23',16,TRUE,'Mahogany',5.95,21.25,202.69,83.38,'2023-02-22','2023-02-27','2023-11-15','2023-12-02','2021-12-24',187,74.38,6.32,20.82,47.24,8.5,27.99,63.51,25,11.99,'Screen 16',82.3,NOW(),NOW()),
('e47fea2c-3d78-4704-9d37-f9950ee8291c','a7b8fac6-1745-416f-8eed-a4426de4f0b1','2023-2024','2016-01-22',93,185,'non-organic','sometimes','non-organic','rarely','2023-01-23','2021-01-03',25,TRUE,'Coconut',6.69,20.43,270.66,86.89,'2024-02-02','2024-01-30','2024-12-15','2024-12-04','2022-12-31',188,126.74,9.9,45.47,71.37,7.81,35.88,56.31,2,11.29,'Screen 16',110.74,NOW(),NOW()),
('ac2bc6c7-9c23-4deb-ab55-d81dbb956b2c','a7b8fac6-1745-416f-8eed-a4426de4f0b1','2024-2025','2016-01-22',105,185,'non-organic','sometimes','non-organic','sometimes','2024-01-05','2021-11-16',26,TRUE,'Banana',6.62,21.82,152.99,81.19,'2025-01-22','2025-02-01','2025-09-15','2025-09-01','2023-12-12',186,120.22,14.51,28.99,76.72,12.07,24.11,63.82,22,10.73,'Screen 17',124.73,NOW(),NOW()),
('f400ed94-623c-4bd6-8ab8-34f7fbbc2ce9','1caee4c8-5f87-46f0-9aa3-1c1521c87055','2021-2022','2014-06-06',88,131,'both','often','both','often','2016-05-28','2014-07-08',23,TRUE,'Ipil-ipil',5.42,23.51,275.45,75.7,'2021-12-08','2021-12-09','2022-10-15','2022-11-03',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,9,11.76,'Screen 18',44.48,NOW(),NOW()),
('b5fca7a4-48d3-458e-b2e3-65decb38b9b8','1caee4c8-5f87-46f0-9aa3-1c1521c87055','2022-2023','2014-06-06',100,131,'both','often','both','sometimes','2021-12-27','2020-08-04',17,TRUE,'Madre de Cacao',6.42,25.44,183.76,81.64,'2023-02-28','2023-02-24','2023-10-15','2023-10-26','2021-11-27',131,58.47,9.48,20.2,28.79,16.22,34.54,49.24,12,11.96,'Screen 15',64.08,NOW(),NOW()),
('429a82a8-97a7-4d16-bdb9-cabd54d39847','1caee4c8-5f87-46f0-9aa3-1c1521c87055','2023-2024','2014-06-06',112,131,'both','often','both','often','2023-01-27','2021-03-08',23,TRUE,'Madre de Cacao',6.76,22.63,197.22,86.3,'2024-02-02','2024-02-04','2024-10-15','2024-10-31','2022-12-24',130,174.1,19.83,45.61,108.66,11.39,26.2,62.41,3,11.08,'Screen 17',202.78,NOW(),NOW()),
('1ac16e57-4337-40d6-bcd8-fedd162bce09','1caee4c8-5f87-46f0-9aa3-1c1521c87055','2024-2025','2014-06-06',124,131,'both','often','both','often','2023-12-28','2022-05-07',20,TRUE,'Coconut',6.37,18.71,181.06,76.3,'2025-01-03','2025-01-07','2025-09-15','2025-09-16','2023-11-23',132,150.13,19.95,43.93,86.25,13.29,29.26,57.45,30,11.82,'Screen 17',147.78,NOW(),NOW()),
('621df8cd-8237-416e-9a09-992207b047f4','2bc7aab7-2a95-42c5-9c37-29f1d9d15a47','2021-2022','2011-02-20',128,236,'both','often','both','often','2012-08-15','2011-09-20',11,TRUE,'Ipil-ipil',6.07,19.77,184.64,75.12,'2022-02-20','2022-02-27','2022-11-15','2022-11-02',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,21,12.51,'Screen 18',128.69,NOW(),NOW()),
('1272cf05-0289-4890-98d0-a15cdb1b3b23','2bc7aab7-2a95-42c5-9c37-29f1d9d15a47','2022-2023','2011-02-20',140,236,'both','often','both','sometimes','2022-01-10','2020-02-20',23,TRUE,'Ipil-ipil',6.29,20.44,224.55,78.97,'2023-01-26','2023-01-28','2023-11-15','2023-11-05','2021-12-14',233,225.47,28.75,59.52,137.2,12.75,26.4,60.85,10,11.81,'Screen 16',250.02,NOW(),NOW()),
('a68d6dc3-1f22-4c2f-a1ea-8a16f8df3637','2bc7aab7-2a95-42c5-9c37-29f1d9d15a47','2023-2024','2011-02-20',152,236,'both','often','both','sometimes','2022-11-20','2021-11-25',12,TRUE,'Mahogany',5.7,18.41,194.49,78.79,'2023-12-03','2023-12-03','2024-09-15','2024-09-29','2022-10-29',237,191.1,28.91,64.53,97.65,15.13,33.77,51.1,18,11.86,'Screen 15',168.43,NOW(),NOW()),
('aed0900d-8705-4a6a-adea-b8c4a4e25534','2bc7aab7-2a95-42c5-9c37-29f1d9d15a47','2024-2025','2011-02-20',164,236,'both','often','both','often','2024-01-06','2022-05-16',20,TRUE,'Ipil-ipil',6.3,23.91,134.9,79.28,'2025-02-18','2025-02-20','2025-12-15','2026-01-03','2023-12-07',234,171.29,24.82,59.4,87.07,14.49,34.68,50.83,23,11.37,'Screen 17',163.65,NOW(),NOW()),
('63d289e6-d607-482a-b78c-03469f54e5ee','48e1cc01-80fc-44ee-94ad-66a8818a587a','2021-2022','2019-01-22',33,184,'non-organic','sometimes','non-organic','sometimes','2020-04-16','2018-05-27',23,TRUE,'Banana',5.81,20.97,193.45,82.73,'2021-12-24','2022-01-03','2022-10-15','2022-10-13',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,19,11.28,'Screen 15',142.49,NOW(),NOW()),
('ec6d75a4-2652-4cbd-a66b-06f2877ddbe6','48e1cc01-80fc-44ee-94ad-66a8818a587a','2022-2023','2019-01-22',45,184,'non-organic','sometimes','non-organic','rarely','2021-11-21','2020-03-31',20,TRUE,'Ipil-ipil',6.12,21.75,208.04,83.25,'2023-02-05','2023-02-09','2023-11-15','2023-11-13','2021-10-25',184,66.2,8.81,17.43,39.96,13.31,26.33,60.36,15,13.1,'Screen 17',63.02,NOW(),NOW()),
('16ba7659-38b8-49d2-ac8f-b64adc3607af','48e1cc01-80fc-44ee-94ad-66a8818a587a','2023-2024','2019-01-22',57,184,'non-organic','sometimes','non-organic','rarely','2023-02-11','2021-09-19',17,TRUE,'Ipil-ipil',5.81,21.23,191.03,82.76,'2024-02-07','2024-02-07','2024-12-15','2025-01-05','2023-01-09',181,171.04,19.28,42.95,108.82,11.27,25.11,63.62,40,11.94,'Screen 16',171.63,NOW(),NOW()),
('6edaa00d-930d-4949-b236-1b94dcc0d64f','48e1cc01-80fc-44ee-94ad-66a8818a587a','2024-2025','2019-01-22',69,184,'non-organic','sometimes','non-organic','rarely','2024-01-29','2022-03-10',23,TRUE,'Falcata',5.67,22.77,170.05,78.23,'2024-12-23','2024-12-31','2025-09-15','2025-09-05','2024-01-07',184,114.12,15.13,27.06,71.93,13.26,23.71,63.03,45,11.97,'Screen 18',118.35,NOW(),NOW()),
('690b6ff2-961e-4f26-9497-b3ed10bacc01','c74959ef-9dec-4c60-97fb-fa4942d81a9e','2021-2022','2017-05-19',53,141,'none','never','none','never','2018-11-19','2017-11-24',12,FALSE,NULL,5.55,19.87,186.84,81.45,'2022-02-02','2022-02-09','2022-11-15','2022-11-28',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,13,11.17,'Screen 16',78.3,NOW(),NOW()),
('37a3e923-cbbc-4237-8aeb-438afba05bdf','c74959ef-9dec-4c60-97fb-fa4942d81a9e','2022-2023','2017-05-19',65,141,'none','never','none','never','2021-12-23','2020-04-02',21,FALSE,NULL,5.95,21.54,249.23,80.74,'2023-01-01','2023-01-11','2023-09-15','2023-09-19','2021-11-25',141,21.15,1.55,3.59,16.0,7.35,16.99,75.66,41,11.12,'Screen 16',20.56,NOW(),NOW()),
('58ea6036-d5ab-4745-a2bd-1e8e9eab5d21','c74959ef-9dec-4c60-97fb-fa4942d81a9e','2023-2024','2017-05-19',77,141,'none','never','none','never','2023-01-18','2021-09-25',16,FALSE,NULL,6.22,22.09,199.18,75.53,'2024-01-11','2024-01-08','2024-10-15','2024-10-03','2022-12-21',144,21.15,1.32,5.26,14.57,6.23,24.86,68.91,34,10.82,'Screen 17',22.77,NOW(),NOW()),
('fa4b391f-cd5f-4d96-bc0a-700afde9e549','c74959ef-9dec-4c60-97fb-fa4942d81a9e','2024-2025','2017-05-19',89,141,'none','never','none','never','2024-02-11','2022-09-19',17,FALSE,NULL,5.88,22.06,220.71,78.51,'2025-01-08','2025-01-15','2025-11-15','2025-11-12','2024-01-07',139,21.15,2.13,4.79,14.24,10.05,22.63,67.32,32,11.89,'Screen 15',23.44,NOW(),NOW()),
('187e4c5a-761e-4fc4-9b2c-a04f044e232d','058bcdad-90b0-438c-8016-e16bcaf6a90c','2021-2022','2012-06-04',112,195,'none','never','none','never','2014-04-03','2012-05-13',23,FALSE,NULL,6.26,21.53,239.4,77.13,'2021-12-19','2021-12-17','2022-10-15','2022-10-12',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25,11.44,'Screen 15',84.08,NOW(),NOW()),
('82cd715b-3fdf-4ede-b4c6-1031f7772af9','058bcdad-90b0-438c-8016-e16bcaf6a90c','2022-2023','2012-06-04',124,195,'none','never','none','never','2021-11-22','2020-04-01',20,FALSE,NULL,5.79,22.41,227.53,80.73,'2023-01-20','2023-01-20','2023-11-15','2023-11-20','2021-10-24',196,29.25,2.1,7.33,19.82,7.19,25.05,67.76,31,12.29,'Screen 17',26.07,NOW(),NOW()),
('59431cb7-78e7-4b6f-8177-85023642763f','058bcdad-90b0-438c-8016-e16bcaf6a90c','2023-2024','2012-06-04',136,195,'none','never','none','never','2022-12-03','2021-09-09',15,FALSE,NULL,6.06,21.46,170.44,79.05,'2024-02-13','2024-02-21','2024-10-15','2024-11-01','2022-11-11',197,29.25,3.01,6.77,19.47,10.3,23.15,66.55,30,12.9,'Screen 16',30.54,NOW(),NOW()),
('4ab0304d-16ce-4e2e-803e-021506f1baa3','058bcdad-90b0-438c-8016-e16bcaf6a90c','2024-2025','2012-06-04',148,195,'none','never','none','never','2023-12-24','2022-10-30',14,FALSE,NULL,6.46,20.45,261.04,81.02,'2024-12-16','2024-12-15','2025-08-15','2025-08-25','2023-11-29',196,29.25,3.83,5.48,19.94,13.09,18.75,68.16,29,11.99,'Screen 18',29.12,NOW(),NOW()),
('a0537e0b-7363-48d9-82b9-060281197274','f4314371-80de-47b9-a67e-aed954435440','2023-2024','2022-08-16',14,115,'organic','rarely','non-organic','never','2024-12-14','2024-02-18',10,TRUE,'Coconut',5.64,23.44,183.0,74.05,'2024-01-06','2024-01-15','2024-11-15','2024-12-02','2024-11-22',116,76.83,10.41,17.55,48.87,13.55,22.84,63.61,23,12.11,'Screen 17',86.15,NOW(),NOW()),
('054ced7f-94ae-461c-b981-fbe1b7b2fbf8','f4314371-80de-47b9-a67e-aed954435440','2024-2025','2022-08-16',26,115,'organic','rarely','non-organic','never','2023-09-06','2021-09-16',24,TRUE,'Ipil-ipil',6.39,22.19,305.0,75.62,'2024-12-10','2024-12-06','2025-09-15','2025-09-17',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,19,12.59,'Screen 18',84.25,NOW(),NOW()),
('b71e640b-de25-40b1-a19f-33b02397a2b4','50d6a4c3-800d-4b97-bfda-b01d5ac9c0b3','2021-2022','2010-08-19',134,215,'both','often','both','often','2012-06-15','2010-09-24',21,TRUE,'Coconut',6.08,23.89,227.4,79.4,'2021-12-27','2021-12-28','2022-08-15','2022-08-23',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,19,12.15,'Screen 16',99.29,NOW(),NOW()),
('8440fe58-c0d7-40a0-b53b-583810cc30d8','50d6a4c3-800d-4b97-bfda-b01d5ac9c0b3','2022-2023','2010-08-19',146,215,'both','often','both','sometimes','2022-02-09','2020-08-18',18,TRUE,'Mahogany',6.36,24.77,216.64,84.43,'2022-12-25','2023-01-02','2023-08-15','2023-08-18','2022-01-10',218,92.77,14.09,29.97,48.7,15.19,32.31,52.5,23,12.34,'Screen 16',86.96,NOW(),NOW()),
('98886176-ae20-430f-ae7b-85edcca30cb1','50d6a4c3-800d-4b97-bfda-b01d5ac9c0b3','2023-2024','2010-08-19',158,215,'both','often','both','sometimes','2023-01-07','2021-03-18',22,TRUE,'Coconut',5.86,21.96,223.58,77.86,'2024-01-03','2023-12-31','2024-10-15','2024-11-02','2022-12-05',217,250.27,35.91,64.32,150.04,14.35,25.7,59.95,12,12.96,'Screen 17',252.56,NOW(),NOW()),
('66230f9a-adff-4098-b9c1-694bcca5a21f','50d6a4c3-800d-4b97-bfda-b01d5ac9c0b3','2024-2025','2010-08-19',170,215,'both','often','both','sometimes','2024-01-03','2023-03-09',10,TRUE,'Mahogany',6.75,23.95,262.01,75.45,'2025-02-22','2025-02-28','2025-10-15','2025-11-04','2023-12-04',215,73.56,12.03,19.13,42.4,16.35,26.01,57.64,10,11.89,'Screen 16',75.26,NOW(),NOW()),
('37ba76dc-ad48-48de-89f1-e22d36831a61','d0042b09-ec1d-4cf3-a59a-6277b33cba70','2023-2024','2022-06-15',16,34,'none','never','none','never','2024-12-01','2023-10-08',14,FALSE,NULL,6.16,22.27,213.59,78.63,'2023-12-02','2023-11-30','2024-10-15','2024-10-30','2024-11-05',31,5.1,0.29,1.49,3.32,5.77,29.19,65.04,14,12.7,'Screen 18',5.15,NOW(),NOW()),
('dbe35928-927f-47ce-814f-131130d5fb9b','d0042b09-ec1d-4cf3-a59a-6277b33cba70','2024-2025','2022-06-15',28,34,'none','never','none','never','2023-09-26','2022-08-02',14,FALSE,NULL,6.48,24.06,193.71,83.99,'2024-12-21','2024-12-27','2025-09-15','2025-09-06',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,24,12.84,'Screen 16',11.08,NOW(),NOW()),
('5315120c-96df-4ab6-a3b6-b9efa7a4831f','afdbcd84-ff38-4fcf-bc2a-b3af53fdfafe','2021-2022','2014-11-07',83,133,'organic','rarely','non-organic','rarely','2016-06-13','2015-06-19',12,FALSE,NULL,5.49,22.92,124.42,79.81,'2021-12-17','2021-12-26','2022-08-15','2022-08-01',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,29,12.59,'Screen 18',86.05,NOW(),NOW()),
('8c9d2edc-b19b-4757-8707-cac83327c587','afdbcd84-ff38-4fcf-bc2a-b3af53fdfafe','2022-2023','2014-11-07',95,133,'organic','rarely','non-organic','never','2021-12-22','2020-07-30',17,FALSE,NULL,5.75,21.5,243.04,75.62,'2023-01-05','2023-01-12','2023-09-15','2023-09-10','2021-11-30',130,78.15,12.68,24.59,40.88,16.22,31.47,52.31,24,10.7,'Screen 16',78.47,NOW(),NOW()),
('4ade8eaa-60a3-4fcf-acc0-a7314f9d3f19','afdbcd84-ff38-4fcf-bc2a-b3af53fdfafe','2023-2024','2014-11-07',107,133,'organic','rarely','non-organic','rarely','2023-02-13','2021-12-20',14,FALSE,NULL,5.63,24.4,228.1,79.52,'2023-12-05','2023-12-03','2024-10-15','2024-10-25','2023-01-13',132,32.91,2.47,8.11,22.33,7.51,24.65,67.84,42,11.69,'Screen 16',30.83,NOW(),NOW()),
('1f177bfa-8b77-4c36-be35-e8cbc7c52876','afdbcd84-ff38-4fcf-bc2a-b3af53fdfafe','2024-2025','2014-11-07',119,133,'organic','rarely','non-organic','rarely','2023-12-04','2022-05-13',19,FALSE,NULL,6.13,23.34,237.48,83.59,'2025-01-07','2025-01-08','2025-11-15','2025-11-26','2023-11-10',132,65.03,10.14,13.16,41.73,15.6,20.23,64.17,27,12.51,'Screen 16',66.54,NOW(),NOW()),
('69573321-0bb6-4634-878e-af5ab3433f57','ee1c8684-863d-4bc2-8a76-56639743cfbf','2021-2022','2010-07-12',135,81,'none','never','none','never','2012-03-23','2011-03-29',12,FALSE,NULL,6.62,22.11,297.85,86.7,'2021-12-13','2021-12-21','2022-09-15','2022-10-05',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,33,12.47,'Screen 15',24.98,NOW(),NOW()),
('0904fdfc-317f-49e2-8a00-6c0a6436851f','ee1c8684-863d-4bc2-8a76-56639743cfbf','2022-2023','2010-07-12',147,81,'none','never','none','never','2021-11-22','2020-05-31',18,FALSE,NULL,5.85,20.63,278.73,85.44,'2023-01-21','2023-01-29','2023-10-15','2023-10-26','2021-11-01',78,12.15,0.93,2.82,8.4,7.65,23.25,69.1,32,12.06,'Screen 16',11.51,NOW(),NOW()),
('e2ccd02b-0f16-47e9-a7a6-60a9ef5047db','ee1c8684-863d-4bc2-8a76-56639743cfbf','2023-2024','2010-07-12',159,81,'none','never','none','never','2023-01-08','2020-11-19',26,FALSE,NULL,5.77,24.41,296.23,76.46,'2024-02-21','2024-02-18','2024-11-15','2024-11-28','2022-12-17',83,12.15,0.76,2.55,8.85,6.22,20.95,72.83,43,11.54,'Screen 16',10.69,NOW(),NOW()),
('0bd8b6ea-e955-4dec-9cc3-e097073107ff','ee1c8684-863d-4bc2-8a76-56639743cfbf','2024-2025','2010-07-12',171,81,'none','never','none','never','2023-12-26','2022-01-05',24,FALSE,NULL,6.13,22.48,151.47,81.46,'2024-12-04','2024-11-29','2025-10-15','2025-10-09','2023-12-04',83,12.15,1.42,4.25,6.48,11.72,34.94,53.34,4,11.99,'Screen 17',12.55,NOW(),NOW()),
('52e3a869-4f07-4329-a9a6-d61f28cc1f97','8f0c2ff0-760a-47d2-a144-3014c6031747','2021-2022','2013-10-24',96,37,'organic','rarely','organic','rarely','2015-05-02','2014-03-08',14,FALSE,NULL,5.46,23.17,267.24,82.15,'2021-12-11','2021-12-19','2022-09-15','2022-10-04',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,9,12.36,'Screen 15',20.28,NOW(),NOW()),
('facdd490-ac53-4ad2-a2a6-7a6a69291dc0','8f0c2ff0-760a-47d2-a144-3014c6031747','2022-2023','2013-10-24',108,37,'organic','rarely','organic','never','2021-12-05','2019-11-16',25,FALSE,NULL,6.29,23.88,174.81,76.49,'2023-02-22','2023-02-20','2023-10-15','2023-11-02','2021-11-14',34,5.55,0.52,1.38,3.64,9.45,24.95,65.6,7,12.71,'Screen 16',4.81,NOW(),NOW()),
('c4261c79-d25d-47b1-a963-7accbf40629c','8f0c2ff0-760a-47d2-a144-3014c6031747','2023-2024','2013-10-24',120,37,'organic','rarely','organic','never','2022-12-21','2021-10-27',14,FALSE,NULL,6.34,20.39,290.46,74.13,'2024-02-24','2024-03-03','2024-10-15','2024-10-21','2022-11-24',35,13.03,1.4,4.82,6.81,10.73,37.0,52.27,23,12.38,'Screen 17',14.84,NOW(),NOW()),
('dc8f9f29-f5dc-49a9-a14b-06012ee5df60','8f0c2ff0-760a-47d2-a144-3014c6031747','2024-2025','2013-10-24',132,37,'organic','rarely','organic','never','2023-11-14','2021-09-25',26,FALSE,NULL,5.97,22.77,150.79,77.34,'2024-12-13','2024-12-10','2025-09-15','2025-09-19','2023-10-23',40,11.74,1.83,3.7,6.21,15.57,31.54,52.89,36,11.71,'Screen 18',10.01,NOW(),NOW()),
('4404d1e7-df68-43e1-b21f-246b0c13634c','835061c7-e763-4f15-8110-f6ea82c21ce0','2021-2022','2012-07-01',111,64,'none','never','none','never','2014-04-15','2012-09-22',19,FALSE,NULL,6.75,23.11,186.08,78.87,'2021-12-24','2021-12-26','2022-08-15','2022-08-01',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,42,10.83,'Screen 17',39.55,NOW(),NOW()),
('c5eeaa90-c3da-4888-856a-169b5ed974fc','835061c7-e763-4f15-8110-f6ea82c21ce0','2022-2023','2012-07-01',123,64,'none','never','none','never','2022-01-24','2021-03-30',10,FALSE,NULL,5.74,23.22,202.3,82.21,'2022-12-17','2022-12-19','2023-09-15','2023-10-02','2021-12-29',61,9.6,1.22,2.41,5.97,12.67,25.1,62.23,45,11.3,'Screen 17',8.47,NOW(),NOW()),
('48b5b72f-172d-4a43-8b75-d97eb6b64dfc','835061c7-e763-4f15-8110-f6ea82c21ce0','2023-2024','2012-07-01',135,64,'none','never','none','never','2022-11-14','2020-09-25',26,FALSE,NULL,6.26,21.64,272.07,79.66,'2024-02-04','2024-02-03','2024-12-15','2024-12-26','2022-10-10',61,9.6,0.58,3.16,5.85,6.07,32.96,60.97,32,11.03,'Screen 16',8.96,NOW(),NOW()),
('9861f710-9af7-4a5e-a052-f30fd8d08f19','835061c7-e763-4f15-8110-f6ea82c21ce0','2024-2025','2012-07-01',147,64,'none','never','none','never','2023-11-29','2022-04-08',20,FALSE,NULL,5.77,24.46,204.1,83.36,'2025-01-09','2025-01-11','2025-09-15','2025-09-13','2023-10-26',62,9.6,0.89,2.88,5.83,9.24,29.98,60.78,37,12.13,'Screen 16',8.52,NOW(),NOW()),
('cd4467cf-4f51-4ed9-87af-4c82687d671e','123aa3d3-dab1-46a5-9b49-07c3695381db','2023-2024','2022-08-19',14,139,'organic','rarely','organic','never','2025-01-20','2023-03-02',23,FALSE,NULL,5.9,19.97,200.31,82.58,'2024-01-09','2024-01-07','2024-09-15','2024-09-11','2024-12-25',142,42.27,2.97,10.94,28.36,7.02,25.89,67.09,30,12.62,'Screen 15',39.11,NOW(),NOW()),
('768f0fbc-627e-4c87-a28b-074bc2e10517','123aa3d3-dab1-46a5-9b49-07c3695381db','2024-2025','2022-08-19',26,139,'organic','rarely','organic','never','2023-11-02','2022-11-07',12,FALSE,NULL,5.3,22.96,293.63,79.12,'2025-01-09','2025-01-09','2025-09-15','2025-09-26',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,36,12.09,'Screen 16',48.28,NOW(),NOW()),
('3c9558f1-2c84-4e71-90b6-6d70f9e07026','79f13140-a1e8-42bb-a80f-21dc4cd72ef3','2021-2022','2010-04-14',138,101,'non-organic','sometimes','non-organic','sometimes','2011-04-20','2010-05-25',11,TRUE,'Banana',6.38,23.67,300.42,76.09,'2022-01-22','2022-01-19','2022-11-15','2022-11-17',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,38,11.08,'Screen 15',40.29,NOW(),NOW()),
('6bd6673f-535f-4773-abf1-ee5dfc0c4eab','79f13140-a1e8-42bb-a80f-21dc4cd72ef3','2022-2023','2010-04-14',150,101,'non-organic','sometimes','non-organic','rarely','2021-11-09','2020-03-19',20,TRUE,'Coconut',6.59,19.98,284.37,74.55,'2023-01-27','2023-02-03','2023-10-15','2023-10-02','2021-10-18',101,52.68,6.21,13.89,32.58,11.78,26.37,61.85,27,11.38,'Screen 16',61.53,NOW(),NOW()),
('5a41872a-dd33-4153-92b6-adf812debc18','79f13140-a1e8-42bb-a80f-21dc4cd72ef3','2023-2024','2010-04-14',162,101,'non-organic','sometimes','non-organic','rarely','2023-01-02','2021-11-08',14,TRUE,'Mahogany',5.73,19.05,228.47,77.61,'2024-01-18','2024-01-28','2024-09-15','2024-09-06','2022-12-05',100,36.62,4.76,9.81,22.06,12.99,26.78,60.23,19,11.87,'Screen 16',39.21,NOW(),NOW()),
('a4e90eab-a230-42ca-9a69-a039cb666a4b','79f13140-a1e8-42bb-a80f-21dc4cd72ef3','2024-2025','2010-04-14',174,101,'non-organic','sometimes','non-organic','sometimes','2024-02-03','2022-05-14',21,TRUE,'Madre de Cacao',6.02,21.92,250.66,78.64,'2025-01-13','2025-01-16','2025-09-15','2025-09-02','2024-01-01',100,39.66,2.68,9.44,27.54,6.76,23.81,69.43,25,10.86,'Screen 17',34.52,NOW(),NOW()),
('3c5daebc-2252-4a6c-96e4-cd9fc05ce626','a59b4841-8111-4535-a88e-6133736bb737','2021-2022','2018-07-31',39,98,'organic','never','organic','never','2020-05-25','2019-01-01',17,FALSE,NULL,5.69,25.09,162.45,81.37,'2022-02-02','2022-02-04','2022-12-15','2022-12-25',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,22,12.65,'Screen 16',38.03,NOW(),NOW()),
('a208c350-54d2-4b4f-b50d-142c72f0a5b7','a59b4841-8111-4535-a88e-6133736bb737','2022-2023','2018-07-31',51,98,'organic','never','organic','never','2022-01-26','2020-05-06',21,FALSE,NULL,6.66,24.34,142.53,81.81,'2023-02-05','2023-02-06','2023-11-15','2023-12-05','2021-12-24',97,19.06,2.58,5.26,11.21,13.55,27.61,58.84,15,10.91,'Screen 15',17.75,NOW(),NOW()),
('73747492-c9cd-47ed-bc32-da8420bc7d3c','a59b4841-8111-4535-a88e-6133736bb737','2023-2024','2018-07-31',63,98,'organic','never','organic','never','2022-12-28','2020-11-08',26,FALSE,NULL,6.35,21.91,197.27,80.97,'2024-01-23','2024-01-23','2024-10-15','2024-10-04','2022-12-07',95,17.28,1.34,3.97,11.97,7.76,22.95,69.29,14,12.35,'Screen 16',19.37,NOW(),NOW()),
('4eba2d10-50a1-479a-8a5b-bf7428462836','a59b4841-8111-4535-a88e-6133736bb737','2024-2025','2018-07-31',75,98,'organic','never','organic','never','2023-11-22','2022-03-02',21,FALSE,NULL,5.78,22.93,233.79,80.72,'2025-01-05','2025-01-05','2025-11-15','2025-11-28','2023-10-31',101,14.7,1.23,3.21,10.25,8.39,21.87,69.74,30,11.98,'Screen 17',13.39,NOW(),NOW()),
('5ea6e7a7-f548-4588-8827-a4c823cf51c4','1f1f65dd-f84d-476e-b8cb-b47c34b42eb9','2023-2024','2022-10-15',12,37,'non-organic','often','both','sometimes','2025-02-08','2023-11-16',15,TRUE,'Coconut',5.57,21.48,243.5,78.14,'2023-12-23','2023-12-30','2024-10-15','2024-10-03','2025-01-08',35,26.71,4.0,9.11,13.6,14.97,34.1,50.93,22,12.9,'Screen 16',28.68,NOW(),NOW()),
('2f9b7e5f-0d9b-4fa3-b24d-53c4b0672edf','1f1f65dd-f84d-476e-b8cb-b47c34b42eb9','2024-2025','2022-10-15',24,37,'non-organic','often','both','often','2023-12-26','2022-05-05',20,TRUE,'Madre de Cacao',5.55,23.15,185.45,86.5,'2024-12-27','2025-01-01','2025-09-15','2025-09-01',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,12,11.56,'Screen 15',17.58,NOW(),NOW()),
('0037b71d-79a0-443e-ae3c-339ff825a44e','89f90985-203f-4aa7-a0b2-e7e5a3ff0ecb','2021-2022','2010-06-04',136,40,'none','never','none','never','2011-06-28','2009-09-06',22,FALSE,NULL,5.86,21.74,206.91,76.61,'2022-01-12','2022-01-19','2022-09-15','2022-10-01',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,36,12.12,'Screen 16',15.25,NOW(),NOW()),
('87a92c08-793e-40fb-8397-9d58e6fe913f','89f90985-203f-4aa7-a0b2-e7e5a3ff0ecb','2022-2023','2010-06-04',148,40,'none','never','none','never','2021-12-06','2021-01-10',11,FALSE,NULL,5.37,21.07,195.74,85.51,'2022-12-13','2022-12-13','2023-10-15','2023-10-05','2021-11-03',41,6.0,0.36,1.47,4.17,5.97,24.57,69.46,43,13.19,'Screen 17',6.35,NOW(),NOW()),
('6b80cdb9-a1f6-441c-816b-4fb39e7b8029','89f90985-203f-4aa7-a0b2-e7e5a3ff0ecb','2023-2024','2010-06-04',160,40,'none','never','none','never','2023-02-16','2022-04-22',10,FALSE,NULL,5.88,21.72,232.71,80.91,'2023-12-04','2023-12-09','2024-08-15','2024-08-13','2023-01-15',40,6.0,0.78,1.35,3.87,13.05,22.52,64.43,34,12.38,'Screen 17',6.49,NOW(),NOW()),
('1fbb1943-2b65-421e-a4dd-95b3cbb51d95','89f90985-203f-4aa7-a0b2-e7e5a3ff0ecb','2024-2025','2010-06-04',172,40,'none','never','none','never','2024-01-23','2022-12-29',13,FALSE,NULL,5.53,19.26,222.94,83.47,'2025-01-01','2025-01-09','2025-09-15','2025-09-19','2023-12-30',43,6.0,0.58,1.76,3.66,9.65,29.4,60.95,33,12.16,'Screen 16',5.3,NOW(),NOW())
ON CONFLICT (id) DO NOTHING;

-- ANALYTICS VIEW

-- ================================================
-- ANALYTICS MASTER VIEW
-- Assembles the flat table for ML training and reporting.
-- previous_season_yield_kg uses LAG() over harvest_records
-- so the model always has the prior season as a predictor.

CREATE OR REPLACE VIEW analytics_master AS
WITH harvest_with_lag AS (
  SELECT
    hr.id,
    hr.cluster_id,
    hr.season,
    hr.actual_harvest_date,
    hr.yield_kg             AS actual_yield_kg,
    hr.grade_fine,
    hr.grade_premium,
    hr.grade_commercial,
    hr.fine_pct             AS fine_grade_pct,
    hr.premium_pct          AS premium_grade_pct,
    hr.commercial_pct       AS commercial_grade_pct,
    LAG(hr.yield_kg)        OVER (PARTITION BY hr.cluster_id ORDER BY hr.actual_harvest_date)
                            AS previous_season_yield_kg,
    LAG(hr.fine_pct)        OVER (PARTITION BY hr.cluster_id ORDER BY hr.actual_harvest_date)
                            AS previous_fine_pct,
    LAG(hr.premium_pct)     OVER (PARTITION BY hr.cluster_id ORDER BY hr.actual_harvest_date)
                            AS previous_premium_pct,
    LAG(hr.commercial_pct)  OVER (PARTITION BY hr.cluster_id ORDER BY hr.actual_harvest_date)
                            AS previous_commercial_pct
  FROM harvest_records hr
)
SELECT
  -- IDENTIFICATION
  f.id                            AS farm_id,
  c.id                            AS cluster_id,
  csd.season                      AS harvest_season,
  c.variety,

  -- PLANT STRUCTURE
  csd.date_planted,
  csd.plant_age_months,
  csd.number_of_plants            AS tree_count,
  c.area_size_sqm                 AS cluster_area_sqm,

  -- MANAGEMENT PRACTICES
  csd.fertilizer_type,
  csd.fertilizer_frequency,
  csd.pesticide_type,
  csd.pesticide_frequency,
  csd.last_pruned_date,
  csd.pruning_interval_months,
  csd.shade_tree_present,

  -- SOIL & ENVIRONMENT
  csd.soil_ph,
  f.elevation_m,
  csd.avg_temp_c,
  csd.avg_rainfall_mm,
  csd.avg_humidity_pct,

  -- CROP STAGES
  csd.actual_flowering_date,
  csd.estimated_harvest_date,
  csd.actual_harvest_date         AS stage_actual_harvest_date,

  -- HISTORICAL PERFORMANCE (from cluster_stage_data pre-harvest snapshot)
  csd.pre_yield_kg                AS pre_snapshot_yield_kg,
  csd.previous_fine_pct          AS pre_snapshot_fine_pct,
  csd.previous_premium_pct       AS pre_snapshot_premium_pct,
  csd.previous_commercial_pct    AS pre_snapshot_commercial_pct,

  -- HISTORICAL PERFORMANCE (computed via LAG from harvest_records � use this for ML)
  hwl.previous_season_yield_kg,
  hwl.previous_fine_pct,
  hwl.previous_premium_pct,
  hwl.previous_commercial_pct,

  -- TARGET VARIABLES
  hwl.actual_yield_kg,
  hwl.fine_grade_pct,
  hwl.premium_grade_pct,
  hwl.commercial_grade_pct,

  -- MODEL TRACKING
  csd.predicted_yield,
  csd.bean_moisture,
  csd.defect_count

FROM farms f
JOIN clusters c
  ON c.farm_id = f.id
JOIN cluster_stage_data csd
  ON csd.cluster_id = c.id
LEFT JOIN harvest_with_lag hwl
  ON  hwl.cluster_id = c.id
  AND hwl.season     = csd.season;


-- VERIFICATION QUERIES

-- ================================================
-- VERIFICATION QUERIES
-- Run after all inserts
-- ================================================

-- Row counts per table
SELECT 'users'              AS tbl, COUNT(*) FROM users
UNION ALL SELECT 'farms',              COUNT(*) FROM farms
UNION ALL SELECT 'clusters',           COUNT(*) FROM clusters
UNION ALL SELECT 'harvest_records',    COUNT(*) FROM harvest_records
UNION ALL SELECT 'cluster_stage_data', COUNT(*) FROM cluster_stage_data;

-- Flat table: all Robusta records with targets populated
SELECT COUNT(*) AS analytics_rows,
       ROUND(AVG(actual_yield_kg),2)      AS avg_yield_kg,
       ROUND(AVG(fine_grade_pct),2)       AS avg_fine_pct,
       ROUND(AVG(premium_grade_pct),2)    AS avg_premium_pct,
       ROUND(AVG(commercial_grade_pct),2) AS avg_commercial_pct,
       ROUND(AVG(plant_age_months),1)     AS avg_plant_age_months,
       ROUND(AVG(soil_ph),2)              AS avg_soil_ph,
       ROUND(AVG(avg_temp_c),2)           AS avg_temp_c,
       ROUND(AVG(avg_rainfall_mm),2)      AS avg_rainfall_mm
FROM analytics_master
WHERE variety = 'Robusta'
  AND actual_yield_kg IS NOT NULL;

-- Season-level yield trend
SELECT harvest_season,
       COUNT(*)                           AS cluster_count,
       ROUND(SUM(actual_yield_kg),2)      AS total_yield_kg,
       ROUND(AVG(actual_yield_kg),2)      AS avg_yield_kg,
       ROUND(AVG(fine_grade_pct),2)       AS avg_fine_pct
FROM analytics_master
WHERE actual_yield_kg IS NOT NULL
GROUP BY harvest_season
ORDER BY harvest_season;

