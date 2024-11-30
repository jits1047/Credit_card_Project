select * from [dbo].[credit_card_transcations]
/*
1- write a query to print top 5 cities with highest spends and their percentage 
contribution of total credit card spends 
*/


with cte1 as (
select city,sum(amount) as total_spend
from credit_card_transcations
group by city)
,total_spend as (select sum(amount) as total_amount from credit_card_transcations)

select top 5 cte1 .*,round(total_spend*1.0/total_amount *100,2) as percentage_contribution 
from cte1 inner join total_spend on 1=1
order by total_spend desc

/*
2- write a query to print highest spend month and amount spent in 
that month for each card type
*/
with cte as (
select card_type,datepart(year,transaction_date) yt
,datepart(month,transaction_date) mt,sum(amount) as total_spend
from credit_card_transcations
group by card_type,datepart(year,transaction_date)
,datepart(month,transaction_date)
--order by card_type,total_spend desc
)
select * from (select *, rank() over(partition by card_type order by total_spend desc) as rn
from cte) a where rn=1

/*
3- write a query to print the transaction details(all columns from the table) 
for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
*/

with cte as (
select *, sum(amount) over (partition by card_type order by transaction_date,
transaction_id asc) as total_spend
from credit_card_transcations
--order by card_type
)
select * from (select *, rank() over (partition by card_type order by total_spend) as rn
from cte where total_spend >= 1000000) a where rn=1

/*
4- write a query to find city which had lowest percentage spend for gold card type
*/

with cte as (
select city,card_type,sum(amount) as amount
,sum(case when card_type = 'Gold' then amount end) as gold_amount 
from credit_card_transcations
group by city,card_type

)
select top 1
city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from cte
group by city
having sum(gold_amount) is not null 
order by gold_ratio

--select distinct card_type from  credit_card_transcations where city = 'kavali'

/*
5- write a query to print 3 columns:  city, highest_expense_type , 
lowest_expense_type (example format : Delhi , bills, Fuel)
*/

select distinct exp_type from credit_card_transcations

with cte as (
select city,exp_type,sum(amount) as total_amount from credit_card_transcations
group by city,exp_type
)
select
city, max(case when rn_asc=1 then exp_type end )as lowest_exp_type
, min(case when rn_desc=1 then exp_type end) as highest_exp_type
from 
(
select *,
rank() over (partition by city order by total_amount desc) rn_desc
,rank() over (partition by city order by total_amount asc) rn_asc
from cte) A
group by city

/*
6- write a query to find percentage contribution of spends by females 
for each expense type
*/
select * from credit_card_transcations

select exp_type,
sum(case when gender = 'F' then amount else 0 end )*1.0/sum(amount) as 
percentage_female_contribution
from credit_card_transcations
group by gender,exp_type
order by exp_type,gender

/*
7- which card and expense type combination saw highest month over 
month growth in Jan-2014
*/

with cte as (
select card_type,exp_type,datepart(year,transaction_date) yt
,datepart(month,transaction_date) mt, sum(amount) as total_spend
from credit_card_transcations
group by card_type,exp_type,datepart(year,transaction_date) 
,datepart(month,transaction_date) )
select top 1 *,(total_spend-prev_mt_spend) as mom_growth
from (
select *
,lag(total_spend) over (partition by card_type,exp_type order by yt,mt) as prev_mt_spend
from cte) a
where prev_mt_spend is not null and	 yt=2014 and mt=1
order by mom_growth desc

/*
9- during weekends which city has highest total spend to total no of transcations ratio 
*/

select top 1 city,sum(amount)*1.0/count(1) as ratio from 
credit_card_transcations
where datepart(weekday,transaction_date) in (1,7)
group by city
order by ratio desc

/*
10- which city took least number of days to reach its 500th transaction after
the first transaction in that city
*/

with cte as (
select *
,ROW_NUMBER() over (partition by city order by transaction_date,transaction_id) as rn
--,rank () over(partition by city order by transaction_date)
from credit_card_transcations
)
select * from cte 
where rn =1 or rn=500


with cte as (
select *
,ROW_NUMBER() over (partition by city order by transaction_date,transaction_id) as rn
--,rank () over(partition by city order by transaction_date)
from credit_card_transcations
)
select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as datediff_1 
from cte 
where rn =1 or rn=500
group by city
--having count(1)=2
order by datediff_1