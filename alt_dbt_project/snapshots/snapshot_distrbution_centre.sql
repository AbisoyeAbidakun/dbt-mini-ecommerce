{% snapshot snapshot_distribution_centre %}
   {{
	config(
		target_schema='alt_dbt_proj',
		unique_key='id',
		strategy='check',
		check_cols=['name','latitude','longitude']
	)
   }}

   SELECT * FROM {{ ref("distribution_centre") }}

{% endsnapshot %}
