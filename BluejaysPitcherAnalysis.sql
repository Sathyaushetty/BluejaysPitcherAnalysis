Select*
From LastPitchBluejays

Select*
From BluejaysPitchingStats

--Question 1 AVG Pitches Per at Bat Analysis

--1a AVG Pitches Per At Bat (LastPitchBlueJays)

Select Avg(1.00* pitch_number) AvgNumofPitchesPerAtBat
From LastPitchBluejays

--1b AVG Pitches Per At Bat Home Vs Away (LastPitchBlueJays) -> Union

Select 
'Home' Typeofgame,
	Avg(1.00* pitch_number) AvgNumofPitchesPerAtBat
From LastPitchBluejays
Where home_team = 'TOR'
Union 
Select
'Away' Typeofgame,
	Avg(1.00* pitch_number) AvgNumofPitchesPerAtBat
From LastPitchBluejays
Where away_team = 'TOR'

--1c AVG Pitches Per At Bat Lefty Vs Righty  -> Case Statement 

Select 
	Avg(case when batter_position = 'L' then 1.00* pitch_number end) LeftyAtBat,
	Avg(case when batter_position = 'R' then 1.00* pitch_number end) RightyAtBat
From LastPitchBluejays


--1d AVG Pitches Per At Bat Lefty Vs Righty Pitcher | Each Away Team -> Partition By

Select Distinct
home_team,
Pitcher_Position,
Avg(1.00* pitch_number) over (partition by home_team, pitcher_position) AvgNumofPitches
From LastPitchBluejays
where away_team = 'TOR'

--1e Top 3 Most Common Pitch for at bat 1 through 10, and total amounts (LastPitchBlueJays)

with totalpitchsequence as (
	Select distinct
		Pitch_name, Pitch_number, 
	count(pitch_name) over (partition by pitch_name,pitch_number) Pitchfrequency
	From LastPitchBluejays
	Where pitch_number < 11
	),
pitchfrequencyquery as (
	select
	pitch_name,
	Pitch_number,
	Pitchfrequency,
	rank() over (Partition by pitch_number order by PitchFrequency desc) PitchFrequencyRanking
From totalpitchsequence
)
Select*
From pitchfrequencyquery
where PitchFrequencyRanking < 4


--1f AVG Pitches Per at Bat Per Pitcher with 20+ Innings | Order in descending (LastPitchBlueJays + BlueJaysPitchingStats)

Select
	BPS.Name,
	Avg(1.00*Pitch_number) AvgPitches
from LastPitchBluejays LPB
join BluejaysPitchingStats BPS on BPS.Pitcher_ID = LPB.pitcher
Where IP>=20
group by BPS.Name
order by Avg(1.00*Pitch_number) Desc

--Question 2 Last Pitch Analysis

--2a Count of the Last Pitches Thrown in Desc Order (LastPitchBlueJays)

Select Pitch_name, count(*) Timesthrown
From lastpitchbluejays
group by pitch_name
order by count(*) desc

--2b Count of the different last pitches Fastball or Offspeed (LastPitchBlueJays)

Select
	sum(case when pitch_name in ('4-Seam Fastball', 'cutter') then 1 else 0 end) Fastball,
	sum(case when pitch_name Not in ('4-Seam Fastball', 'cutter') then 1 else 0 end) Offspeed
from LastPitchBluejays
	
--2c Percentage of the different last pitches Fastball or Offspeed (LastPitchBlueJays)

Select
	100*sum(case when pitch_name in ('4-Seam Fastball', 'cutter') then 1 else 0 end)/count(*) FastballPercent,
	100*sum(case when pitch_name Not in ('4-Seam Fastball', 'cutter') then 1 else 0 end)/count(*) OffspeedPercent
from LastPitchBluejays

--2d Top 5 Most common last pitch for a Relief Pitcher vs Starting Pitcher vs Closer (LastPitchBlueJays + BlueJaysPitchingStats)

Select*
	From(
		Select
		a.Pos,
		a.pitch_name,
		a.timesthrown,
		rank() over(Partition by a.Pos order by a.timesthrown desc) Pitchrank
	From(
		Select BPS.Pos, LPB.pitch_name, count(*) timesthrown
		from LastPitchBluejays LPB
		join BluejaysPitchingStats BPS on BPS.Pitcher_ID = LPB.pitcher
		group by  BPS.Pos, LPB.pitch_name
	) a
)b
Where b.Pitchrank<6


--Question 3 Homerun analysis

--3a What pitches have given up the most HRs (LastPitchBlueJays)

Select pitch_name, count(*) HRs
From LastPitchBluejays
Where events = 'Home_run'
group by pitch_name
order by count(*) desc

--3b Show HRs given up by zone and pitch, show top 5 most common

Select top 5 Zone, Pitch_name,count(*) HRs
From LastPitchBluejays
where events='home_run'
group by zone, pitch_name
order by count(*) desc

--3c Show HRs for each count type -> Balls/Strikes + Type of Pitcher

Select BPS.Pos, LPB.balls,LPB.strikes, count(*) HRs
		from LastPitchBluejays LPB
		join BluejaysPitchingStats BPS on BPS.Pitcher_ID = LPB.pitcher
		where events='Home_run'
		group by BPS.Pos, LPB.balls,LPB.strikes
		order by count(*) desc


--3d Show Each Pitchers Most Common count to give up a HR (Min 30 IP)

with HrcountPitchers as (
Select BPS.Name,LPB.balls,Lpb.strikes,count(*) HRs 
		from LastPitchBluejays LPB
		join BluejaysPitchingStats BPS on BPS.Pitcher_ID = LPB.pitcher
		where events='Home_run' and IP>=30
		group by BPS.Name,LPB.balls,Lpb.strikes
		),
		hrcountranks as (
		Select 
		hcp.Name,
		hcp.balls,
		hcp.strikes,
		hcp.HRs,
		rank() over (partition by name order by HRs desc) hrrank 
		From HrcountPitchers hcp
)
select ht.Name,
		ht.balls,
		ht.strikes,
		ht.HRs
from hrcountranks ht
where hrrank=1


--Question 4 Chris Bassitt

--4a AVG Release speed, spin rate,  strikeouts, most popular zone ONLY USING LastPitchBlueJays

Select
	Avg(release_speed) AvgReleaseSpeed,
	Avg(release_spin_rate) AvgSpinRate,
	Sum(Case when events='strikeout' then 1 else 0 end) strikeouts,
	Max (Zones.zone) as Zone
from lastpitchbluejays LPB
join(
	Select Top 1 pitcher, zone,count(*) Zonenum
	From LastPitchBluejays LPB
	where player_name = 'Bassitt, Chris'
	group by pitcher, zone
	order by count(*) desc
	)
Zones on zones.pitcher=LPB.Pitcher
where player_name = 'Bassitt, Chris'

--4b top pitches for each infield position where total pitches are over 5, rank them

Select*
From(
	Select pitch_name, count(*) timesHit, 'Third' Position
	From LastPitchBluejays
	Where hit_location=5 and player_name = 'Bassitt, Chris'
	group by pitch_name
	union
	Select pitch_name, count(*) timesHit, 'Short' Position
	From LastPitchBluejays
	Where hit_location=6 and player_name = 'Bassitt, Chris'
	group by pitch_name
	Union
	Select pitch_name, count(*) timesHit, 'Second' Position
	From LastPitchBluejays
	Where hit_location=4 and player_name = 'Bassitt, Chris'
	group by pitch_name
	Union
	Select pitch_name, count(*) timesHit, 'First' Position
	From LastPitchBluejays
	Where hit_location=3 and player_name = 'Bassitt, Chris'
	group by pitch_name
)a
Where TimesHit > 4
order by timesHit desc

--4c Show different balls/strikes as well as frequency when someone is on base 

SELECT balls, strikes, count(*) frequency
FROM LastPitchBluejays
WHERE (on_3b is NOT NULL or on_2b is NOT NULL or on_1b is NOT NULL)
and player_name = 'Bassitt, Chris'
group by balls, strikes
order by count(*) desc

--4d What pitch causes the lowest launch speed

SELECT TOP 1 pitch_name, avg(launch_speed * 1.00) LaunchSpeed
FROM LastPitchBluejays
where player_name = 'Bassitt, Chris'
group by pitch_name
order by avg(launch_speed)