select *
from PortfolioProject..CovidDeaths
order by 3,5

--select *
--from PortfolioProject..CovidVaccinations
--order by 3,4

---selecting the CovidDeath Table
select Location, date, total_cases,new_cases,total_deaths, population 
from PortfolioProject..CovidDeaths
order by 3,5

---Total Cases vs Total Deaths


select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as Percentage_of_Death
from PortfolioProject..CovidDeaths
order by 1,2

--Likelihood of Getting Covid in Ireland AS at January 2022

select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as Percentage_of_Death
from PortfolioProject..CovidDeaths
where Location = 'Ireland'
order by 1,2

---Looking at Total cases vs Population
select Location, date, total_cases,population, (total_cases/population)*100 as Cases_by_Population
from PortfolioProject..CovidDeaths
where Location = 'Ireland'
order by 1,2

--Countries with highest infection rate
select Location, MAX(total_cases) as HighestInfectionCount, population, (MAX(total_cases)/population)*100 as Cases_by_Population
from PortfolioProject..CovidDeaths
group by location,population
order by Cases_by_Population desc

--Countries with highest death rate
select Location, MAX(cast(total_deaths as int)) as HighestDeathCount, population, (MAX(total_deaths)/population)*100 as Death_by_Population
from PortfolioProject..CovidDeaths
group by location,population
order by HighestDeathCount desc

Select location,continent
FROM PortfolioProject..CovidDeaths
where continent is Null

-----countries wuth highest death count, eliminating locations with missing continent
select Location, MAX(cast(total_deaths as int)) as HighestDeathCount
from PortfolioProject..CovidDeaths
where continent is not null 
group by location
order by HighestDeathCount desc

------death by continent

select continent, total_deaths, population,  (population / total_deaths) as percentage_of_death_by_continent
from PortfolioProject..CovidDeaths
where continent = 'Europe'  and continent is not null


select continent, MAX(cast(total_deaths as int)) as HighestDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by HighestDeathCount desc

--where continent is null shows the full figures without exclusion,not null above excludes some countries' figures such as Canada, just U.S.A is used for North America Compilation
select location, MAX(cast(total_deaths as int)) as HighestDeathCount
from PortfolioProject..CovidDeaths
where continent is null
group by location
order by HighestDeathCount desc

---Grouped by continent
select continent, MAX(cast(total_deaths as int)) as HighestDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by HighestDeathCount desc


----Total number cases each day across the world

--select date, SUM(new_cases) as TotalCasesEachDay
--From PortfolioProject..CovidDeaths
--where continent is null
--group by date
--order by 1,2

select date, SUM(new_cases) as TotalCasesEachDay
From PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2

select date, SUM(new_cases) as TotalCasesEachDay , SUM(CAST (new_deaths as int)) as TotalDeathsEachDay,  SUM (CAST (new_deaths as int))
/ SUM(new_cases) * 100 as DeathPercentageByDay
From PortfolioProject..CovidDeaths
where continent is not null
group by date 
order by 1,2

---overall death percentage by removing group by date line and unselecting the date colum as shown  in the direct code above
select SUM(new_cases) as TotalCasesEachDay , SUM(CAST (new_deaths as int)) as TotalDeathsEachDay,  SUM (CAST (new_deaths as int))
/ SUM(new_cases) * 100 as DeathPercentageByDay
From PortfolioProject..CovidDeaths
where continent is not null
--group by date 
order by 1,2

----JOINING COVID VACCINATION AND COVID DEATH TABLES

Select *
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date

---total population vs vaccinations, the number of individuals vaccinated compared to total population

Select dea.continent, dea.location, dea.date, dea. population,vac.new_vaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

---Summing up vaccinations by countries through the use of 'PARTITION BY'
Select dea.continent, dea.location, dea.date, dea. population,vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as 
RollingDailyCount---order by date and location because without it, it sums just the total new vaccination in the location (ordering by date leads to serial addition by date)
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is NOT null
order by 2,3

					----OR---


Select dea.continent, dea.location, dea.date, dea. population,vac.new_vaccinations, 
SUM(Cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location)---order by date and location because without it, the sums of the partitioned locations would not be rolled over to new days. It enables rolled over additions(moving summations which adds with each day)
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3



-----Determine total number of people vaccinated compared to the Population, Using the total Rolling Daily Count of each location
-----USING CTE-COMMON TABLE EXPRESSIONS- Temporary set that exist only the duration of a query
-----Temporary table is created which the select,update or delete statement can be used on

With PopvsVac( Continent,Location,Date,Population,New_Vaccinations,RollingDailyCount)
as
(Select dea.continent, dea.location, dea.date, dea. population,vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as 
RollingDailyCount---order by date and location because without it, it sums just the total new vaccination in the location (ordering by date leads to serial addition by date)
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is NOT null
--order by 2,3
)
Select *, ((RollingDailyCount/Population)*100) as PercentageOFPopulationVaccinatedDaily ---- shows the total percentage of people vaccinated in each day of each country
from PopvsVac


---SHOWING ROLLING PERCENTAGES OF POPULATION VACCINATED IN IRELAND DAILY USING CTE
With PopvsVac( Continent,Location,Date,Population,New_Vaccinations,RollingDailyCount)
as
(Select dea.continent, dea.location, dea.date, dea. population,vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as 
RollingDailyCount---order by date and location because without it, it sums just the total new vaccination in the location (ordering by date leads to serial addition by date)
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is NOT null and dea.location = 'Ireland'
--order by 2,3
)
Select *, (RollingDailyCount/Population)*100 ---- shows the total percentage of people vaccinated in each day of each country
from PopvsVac

----CREATION OF TEMPORARY TABLE FOR PERCENTAGE OF VACCINATED, COUNTRY WITH MAX POPULATION VACCINATED
Drop Table #PercentPopulationVaccinated ---Just incase the table needs to be recreated, drop and recreate
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingDailyCount numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea. population,vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as 
RollingDailyCount---order by date and location because without it, it sums just the total new vaccination in the location (ordering by date leads to serial addition by date)
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is NOT null
--order by 2,3
Select *, ((RollingDailyCount/Population)*100 ) as DailyProportionOfPopulationVaccinated---- shows the total percentage of people vaccinated in each day of each country
from #PercentPopulationVaccinated

----CREATING VIEWS TO STORE DATA FOR VISUALIZATION

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea. population,vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as 
RollingDailyCount---order by date and location because without it, it sums just the total new vaccination in the location (ordering by date leads to serial addition by date)
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is NOT null

---View on the total Cases in Ireland compared to the total population
Create View IrishTotalCasesVsPopulation as ---views cannot be created with the order by clause, invalid in views
select Location, date, total_cases,population, (total_cases/population)*100 as Cases_by_Population
from PortfolioProject..CovidDeaths
where Location = 'Ireland'


--Views can be selected and visualized
Select*
From PercentPopulationVaccinated

--Views on the Likelihood of Dying of Covid since its beginning in Ireland
Create View LikelihoodOFDyingOFCovidINIreland as
select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as Percentage_of_Death
from PortfolioProject..CovidDeaths
where Location = 'Ireland'


--VIEWS SHOWING ROLLING PERCENTAGES OF POPULATION VACCINATED IN IRELAND DAILY
Create View RollingPercentagesOfPopulationVaccinatedInIreland as
Select dea.continent, dea.location, dea.date, dea. population,vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as 
RollingDailyCount---order by date and location because without it, it sums just the total new vaccination in the location (ordering by date leads to serial addition by date)
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is NOT null and dea.location = 'Ireland'
