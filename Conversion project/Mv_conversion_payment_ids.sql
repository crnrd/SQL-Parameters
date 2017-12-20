CREATE MATERIALIZED VIEW mv_conversion_payment_ids AS

  select
    id
  from
    payments
  WHERE
    created_at between now()-interval '50 days' and now()-interval '20 days'