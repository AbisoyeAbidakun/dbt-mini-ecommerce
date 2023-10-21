#  DBT Setup
1. Setup venv and activate venv
2. Install Requirements
3. Install extensions :Add to GIT Ignore, YAML, Better Jinja

**DBT-for-bigquery-set-up**
1. Set up dbt via command line: from https://docs.getdbt.com/docs/core/connect-data-platform/bigquery-setup#local-oauth-gcloud-setup
2. gcloud cli ..
2. Authenticate Big-Query - Run this line:
3.
For Mac or Linux
```
gcloud auth application-default login \
  --scopes=https://www.googleapis.com/auth/bigquery,\
https://www.googleapis.com/auth/drive.readonly,\
https://www.googleapis.com/auth/iam.test

```
For Windows:
```
gcloud auth application-default login --scopes=https://www.googleapis.com/auth/bigquery,https://www.googleapis.com/auth/drive.readonly,https://www.googleapis.com/auth/iam.test
```


**CREATING A NEW DBT PROJECT**
1. Get into a new project
2. Run: "dbt init" to create a project : input a name
name: your-project-name
chose database: [1] BigQuery
chose authentication: [1] oauth
enter GCP Project name OR ID:
enter dataset name
thread: 60
select;  US

### NOTE: Always ensure you are inside the folder that has your dbt virtual environment and that your virtual environment is activated

3. Run:
```
dbt debug --config-dir
```

4. open the profiles.yaml :  >> copy the dev profiles and create a productions profile : change the schema

create new branch by clicking on main: switch to the branch >> stage the changes and commit

**Install dbt power user extension:**
1. Search for dbt power user: install
2. Run " command shift p "
3. In the tab tha shows up search for user settings.json : open it and copy the below into the json file:
Add this to the file
```

    // Associated the right file types with the right VSCode extensions
    "files.associations": {
        "*.sql": "jinja-sql"
    },

    // CRUCIAL - you need to change this to terminal.integrated.env.[osx|windows|linux] depending on your system
    // and point it to the folder where your profiles directory is stored!
    "terminal.integrated.env.osx": {
        "DBT_PROFILES_DIR": "fill-this-with-the-path-to-the-folder-containing-your-profiles.yaml-file-on-your-local-file",
		"BIGQUERY_PROJECT": "fill-this-with-your-gcp-pproject-name"
   },

```
Above
 a. if you are on a mac you can add this  ```~/.dbt``` as ```DBT_PROFILES_DIR```
 b. add ```GCP-PROJECT-ID``` as  BIGQUERY_PROJECT NAME
 c. In the  ```terminal.integrated.env.osx``` tag replace "osx" with  either ```windows or linux``` depending on your system's OS

4. run "dbt clean && dbt deps"
5. Restart the vs code or run "command shift p" >> select reload window >> choose the correct python interpreter
6. check the models folder to see if the models have the dbt icon (it works successfully if it does)

**NOTE ADD thelook_ecommerce (ECOMMERCE)  DATA FROM BIGQUERY PUBLIC DATASET**

**Dbt Project Architecture: Source >> Staging >> Intermediate >> Final Table (Fact or Dimensions Table or View)**
(Staging : Usually layer of transformation)
1. Create a staging folder   inside the models folder
2. Inside the staging folder : add a src_ecommerce.yml file and file it up with all the souce description as below:
```
version: 2

sources:
  - name: thelook_ecommerce
    database: bigquery-public-data
    tables:
      - name: inventory_items
      - name: order_items
      - name: orders
      - name: products
      - name: users

```

3. Inside the same root that has the dbt_project.yml create a packages.yml and fill it up as below:

```
packages:
  - package: dbt-labs/dbt_utils
    version: 1.0.0

  - package: calogica/dbt_expectations
    version: [">=0.8.0", "<0.9.0"]

  - package: dbt-labs/codegen
    version: 0.9.0
```
4. Run: ``` dbt deps ```
5. Before running the next command ensure that the bigquery-public-data.thelook_ecommerce has been pulled into your bigquery project: do this on the bigquery

6. To generate the query for the staging orders table,  Run:
	```
	dbt run-operation  --profiles-dir /Users/abidakunabisoye/.dbt generate_base_model --args '{"source_name": "thelook_ecommerce", "table_name": "orders"}'

	```
	or

	```
	 dbt run-operation generate_base_model --args '{"source_name": "thelook_ecommerce", "table_name": "orders"}'

	```
7. Create a stg_ecommerce_orders.sql
8. After running the above query a query is generated : copy the query generated and paste into the stg_ecommerce_orders.sql
9. Run:
``` dbt run ``` or ``` dbt run -s stg_ecommerce_orders ```
10. Generate the yml file for the stg_ecommerce_orders model: run
  ``` dbt run-operation  generate_model_yaml  --args '{"model_names": ["stg_ecommerce_orders"]}'
  ```
  or
  ```
  dbt run-operation  --profiles-dir /Users/path-to-profiles.yaml-file/.dbt generate_model_yaml  --args '{"model_names": ["stg_ecommerce_orders"]}'
  ```
11. Crteated a stg_ecommerce_orders.yml file and paste in the result of the previous command
12. Update the table as shown below
```
## Testing, documentation, Referencing and configuration
version: 2

models:
  - name: stg_ecommerce_orders
    description: " Table describing and detailing every order on per row basis "
    columns:
      - name: order_id
        description: "The order Id of the order"
        tests:
          - not_null
          - unique

      - name: user_id
        description: "User Id who placed the order "
        tests:
          - not_null

      - name: created_at
        description: "When the order was placed"
        tests:
          - not_null

      - name: returned_at
        description: "When the order was returned"
        tests:
          - not_null:
              where: "status = 'Returned'"

      - name: shipped_at
        description: "When the order was shipped"
        tests:
          - not_null:
              where: " delivered_at IS NOT NULL OR status = 'Shipped'"

      - name: delivered_at
        description: "When the order was delivered"
        tests:
          - not_null:
              where: " returned_at IS NOT NULL OR status = 'Complete'"

      - name: status
        description: "Status of the order"
        tests:
          - accepted_values:
               name: expected_order_status
               values:
                - Processing
                - Cancelled
                - shipped
                - Complete
                - Returned

      - name: num_of_item
        description: "Number of items in the order"
        tests:
          - not_null:

```
13. Run : ``` dbt test -s stg_ecommerce_orders ```
14. Running ``` dbt run and dbt test```   == ``` dbt build ```
15. To add descriptions to bigquery: add this under materialisation in the dbt_project.yml file:
```
+materialized: table
+persist_docs:
  relation: true
  columns: true
```
16. Run dbt run --full-refresh
17. Create a intermediate folder in the models folder
18. Add two files into the marts folders: int_order_items_products.sql or int_ecommerce.yml
Fill up the two folders up...
19. Create a marts folder in the models folder
20. Add two files into the marts folders: orders.sql or orders.yml
21.

## Advanced Testing
-- Freshness:
**Setting Severity Level for Test**
1.  Open the dbt_projects.yml file
2.  Add severity level of error for the project to severity warn
```
tests:
  learning:
     +severity: warn # this means all test in the project has a default levle of warn
```
3. Comment out the women on the dbt accepted value test in stg_ecommerce_products
4.  Run
```dbt clean && dbt deps
```
5. dbt test -s  stg_ecommerce_products

**Macros for Testing**
1. Add this to the stg_ecommerce_products.yml file
```
      - name: cost
        description: "How much the product cost the business to purchase"
        tests:
          - not_null
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0

      - name: retail_price
        description: "How much the product retails for on the online store"
        tests:
          - not_null
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0
          - dbt_utils.expression_is_true:
              name: retail_price_not_leading_to_loss
              expression: ">=cost"
```
(Naming the test is useful for debugging what test failed)
2. Run the Test
``` dbt test -s  stg_ecommerce_products
```

**Writing Custom Test**
1. Create file in the tests folder called test_orders_match_order_items_details.sql

## Advanced Data Modelling
1. Create a folder named documents in the models
2. add the folder called doc_order_status.md in
3. paste into it
```
{% docs status %}

The status of the order. Can be one of:
- Processing
- Cancelled
- Shipped
- Complete
- Returned

{% enddocs %}
```
4. Inside the orders.yml and stg_ecommerce_orders.ym; file input  the following:
```
   - name: order_status
        description: "{{ doc('status') }}"
```
5. Run : dbt run -s stg_ecommerce_orders
6. Go to the bigquery table to see the data description

**Add Seed**
1. Describe slowly changing data types:
2. Create a distribution_center.csv file inside the seed folder
3. Paste into it
```
id,name,latitude,longitude
11,Miami FL,25.7617,-80.191788
12,Denver CO,39.7392,-104.9903
```
4. create a seed.yml file inside the seed folder
5. Paste into it:
```
version: 2

seeds:
  - name: seed_distribution_centers_new
    description: "An example of using a CSV file to load data into your warehouse"
    tests:
      - dbt_expectations.expect_table_row_count_to_equal:
          value: 2

    # Column names, descriptions, and tests can all be done as normal
    columns:
      - name: id
        tests:
          - not_null
          - unique
      - name: name
        description: "Distribution center name"
      - name: latitude
      - name: longitude

    # If you want to enforce datatypes, you can do so here
    # Otherwise, BigQuery will do it for you!
    config:
      column_types:
        id: INTEGER
        name: STRING
        latitude: FLOAT
        longitude: FLOAT
```
6. Run : dbt seed
7. Check the bigquery table for the seed materialisation

**Adding Snapshot**
Explain what snap_shot means:
Open this: "https://docs.getdbt.com/docs/build/snapshots"
1. Create a file in the snapshot folder names snapshot_distribution_centre.sql
2. Paste into it:
```
{% snapshot snapshot_distribution_centre %}

{{
    config(
      target_schema='dbt_test',
      unique_key='id',
      strategy='check',
      check_cols=['name', 'latitude', 'longitude']
    )
}}

SELECT * FROM {{ source('thelook_ecommerce', 'distribution_centers') }}

{% endsnapshot %}
```
3. Explain the target_schema concept
4. Add to the src_ecommerce.yml file
```
  - name: distribution_centers
```
4. Run dbt snapshot
5. Update the seed file with the remaining csv row
6. Run dbt seed
7. Run dbt snapshot
8. Run dbt
9. Discribe the changes in the valid to and updated columns

**Explain Models**
### Add Ephemerals
1. Create an sql file called int_initial_order_created in the intermediate folder
```
{{
	config(materialized='ephemeral')
}}


SELECT
	user_id,
	MIN(created_at) AS first_order_created_at

FROM {{ ref('stg_ecommerce_orders') }}
GROUP BY 1

```
2. Add ` -&user_id `to the int_ecommerce.yml to the user_id
3. Add the this below in the int_ecommerce.yml file
```
  - name: int_initial_order_created
    columns:
      - *user_id
      # This would keep the name & tests defined in the anchor, but overwrite the description
```
4. Add this to the orders.sql file
```
-- a good way to demonstrate how to use an ephemeral materialisation
	TIMESTAMP_DIFF(od.created_at, user_data.first_order_created_at, DAY) AS days_since_first_order

```
and join with

```
LEFT JOIN {{ ref('int_initial_order_created') }} AS user_data
	ON od.user_id = user_data.user_id
```
9. run the orders.sql model

### Adding Incremental Models
``` link : https://docs.getdbt.com/docs/build/incremental-models ```
1.  create file named stg_ecommerce_events
2.  Add
 ```
 /* Add this in the config after
        unique_key='event_id',
		on_schema_change='sync_all_columns',
		partition_by={
			"field": "created_at",
			"data_type": "timestamp",
			"granularity": "day"
		}
*/

{{
	config(
		materialized='incremental',

	)
}}

WITH source AS (
	SELECT *

	FROM {{ source('thelook_ecommerce', 'events') }}
	{# first run with " WHERE created_at <= '2023-01-01' then remove where clause "#}
    WHERE created_at <= '2023-01-01'
)

SELECT
	id AS event_id,
	user_id,
	sequence_number,
	session_id,
	created_at,
	ip_address,
	city,
	state,
	postal_code,
	browser,
	traffic_source,
	uri AS web_link,
	event_type,



FROM source

{# Only runs this filter on an incremental run #}
{% if is_incremental() %}

{# The {{ this }} macro is essentially a {{ ref('') }} macro that allows for a circular reference #}
{# Circular reference is when a table references itself #}
WHERE created_at > (SELECT MAX(created_at) FROM {{ this }})

{% endif %}

 ```

3. Run on the where created_at <= '2023-01-01' run without  the below
```
   unique_key='event_id',
   on_schema_change='sync_all_columns',
```
uisng ``` dbt run -s stg_ecommerce_events ```
4. run without WHERE created_at <= '2023-01-01' by commenting it out
5. In the events log you'll see "create" for the first and "merge" for the second
6. Notice and increase in the rows for that table in bigquery
7. If ran again no data will be available
8. Add the unique_key and on_schema_change
```
   unique_key='event_id',
   on_schema_change='sync_all_columns',
```
explain reason
9. Run: dbt run -s stg_ecommerce_events --full-refresh

## Table Partitioning
Partitioning is when a table is cut into partition based on a time_stamp column to make query faster
Can be done on any type of table not only incremental tables
Its useful for cutting down the size of the table
1. Add the below to the stg_ecommerce_events model
```
	partition_by={
			"field": "created_at",
			"data_type": "timestamp",
			"granularity": "day"
		}
```
2. Run dbt run -s stg_ecommerce_events --full-refresh
3. check the target folder and run folder


## Model Governance
links : https://docs.getdbt.com/docs/collaborate/govern/about-model-governance
Model Access: restrict those who have access to a model
Model Contract ; model has certain models and columns, and shape
Model Version: basically versions
**Model Access: restrict those who have access to a model**
1. Add the below to the orders.yml file

```
groups:
  - name: sales
    owner:
      # 'name' or 'email' is required; additional properties allowed
      email: sales@liners.com
      slack: sales-channel
      github: sales-channel-data

models:
  - name: orders
    description: "Table of order level information"
    # Set this model to be a part of the sales group we define above
    # Groups can be defined in another yml file
    config:
      group: sales
    # 3 settings:
    # Private - only other models in the same (sales) group can ref() this model
    # Protected - only other models in the same group or project can ref() this model
    # Public - any other model can ref() this model
    access: protected

```
2. Create the file test_marketing_orders.sql
3. Add : SELECT * FROM {{ ref("orders") }}
4. Run : dbt run -s test_marketing_orders
5. Add groups marketing to orders.yml file

```
  - name: marketing
    owner:
      email: marketing@liners.com
      slack: marketing-channel
      github: marketing-channel-data
```
6. Add {{ config(groups='marketing')}} to the test_marketing_orders model
7. change access to private
8. Run:  dbt run -s test_marketing_orders and Watch error thrown
9. Remove the marketing groups referencing from the test_marketing_orders model to stop error from being thrown.or delete model

Assignments: Implement severity, dbt_expectations.expect_column_values_to_be_between and dbt_utils.expression_is_true on the orders model

**MODEL contract**
1. Overhaul the stg_ecommerce_order_items models with
Note:
- Model contract (run BEFORE model is built)
- Model tests (run AFTER model is built)
- not_null checks are removed from test has it basically duplicates the contract

```
version: 2

models:
  - name: stg_ecommerce_order_items
    description: "Line items from orders"
    config:
      contract:
        enforced: true
    columns:
      - name: order_item_id
        tests:
          - not_null:
              severity: error
          - unique:
              severity: error
        data_type: INTEGER
        constraints:
          - type: not_null

      - name: order_id
        data_type: INTEGER
        tests:
          - not_null
          - relationships:
              to: ref('stg_ecommerce__orders')
              field: order_id

      - name: user_id
        data_type: INTEGER
        tests:
          - not_null

      - name: product_id
        data_type: INTEGER
        tests:
          - not_null
          - relationships:
              to: ref('stg_ecommerce__products')
              field: product_id

      - name: item_sale_price
        data_type: FLOAT64
        description: "How much the item sold for"
        tests:
          - not_null
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0

```
2. Run dbt run -s stg_ecommerce_order_items
3. Comment out the product_id in the above model then run dbt run -s stg_ecommerce_order_items
4. Cast user_id as string in the above model then run bt run -s stg_ecommerce_order_items
watch to see the various contract failure or errors thrown

**MODEL VERSIONS**
1. Create a new folder called product_versions inside it copy and paste the stg_ecommerce_products model and rename it stg_ecommerce_products_v1 remove the brand column
2. In the stg_ecommerce_products.yml file add the following
```
      - name: brand
        description: "Brand of the product"
```
AND
3. Add the brand column to the version 2 (rename current version : stg_ecommerce_products_v2)
```

    latest_version: 2
    versions:
        # Matches what's above -- nothing more needed
        - v: 1
          columns:
          # This means: use the 'columns' list from above, but exclude "brand" as we added it in v2
          - include: all
            exclude: [brand]

        # We added a new brand column
        - v: 2
          # Makes this table stay as stg_ecommerce__products in our database!
          config:
            alias: stg_ecommerce_products
          columns:
          # This means: use the 'columns' list from above
          - include: all

```
NOTE: State this
    - If you don't specify the latest, version, dbt will either look
    - for the unversioned file name (e.g. stg_ecommerce__products.sql), or reference the
    - latest version. In this case, it'd reference version 2 automatically, but this shows you
    - how you could do a pre-release version (e.g. create version 2, but by default dbt points at version 1)
    -  using latest_version: 1
4. Run dbt clean && dbt deps
5. Run dbt run -s stg_ecommerce_products
6. change the latest version to 1 in there stg_ecommerce__products and run the below
7. Run everything up to the int_order_items_products model : dbt run -s +int_order_items_products
8. change the latest version to 2
9. Run everything up to the int_order_items_products model : dbt run -s +int_order_items_products
10. We can reference the models by using "{{ ref('learning', 'stg_ecommerce_products', v='1') }}" or
"{{ ref('learning', 'stg_ecommerce_products', v='2') }}"
11. An alias can be added for a version instead by chaning the stg_ecommerce_products_v2 into stg_ecommerce_products then add an alias to the the version 2  then change the latest version to 2
```
config:
   alias: stg_ecommerce_products

```