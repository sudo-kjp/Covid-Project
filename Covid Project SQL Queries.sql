--select *
--from CovidProject..CovidDeaths
--order by 3,4;

--select *
--from CovidProject..CovidVaccinations
--order by 3,4;

select location, date, total_cases, new_cases, total_deaths, population
from CovidProject..CovidDeaths
order by location, date;
--order by can obviously be kept as 3,4 but for the purpose of a quick glance, will spell it out

-- Comparing total cases to total deaths
-- Shows likelihood of dying if you contract COVID
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidProject..CovidDeaths
order by location, date;

--Specifically for the US
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidProject..CovidDeaths
where location like '%states%'
order by location, date;

-- Comparing total cases to population
-- Shows what percentage of population got COVID
--formatted the date so it would look easier for me.  Issue is, that caused the order to mess up. Will check an alternative later. (or simply clean the time off in Excel)
select location, format(date, '####-##-##') as date, population, total_cases, (total_cases/population)*100 as PopulationInfectionPercentage
from CovidProject..CovidDeaths
where location like '%states%'
order by location, date;

-- Comparing total cases to population
-- Shows what percentage of population got COVID
select location, date, population, total_cases, (total_cases/population)*100 as PopulationInfectionPercentage
from CovidProject..CovidDeaths
where location like '%states%'
order by location, date;

-- Searching countries with highest infection rate relative to population
--problem is this gives us multiple entries per country, when we really need to break it down to the highest for each.
select location, date, population, total_cases, (total_cases/population)*100 as PopulationInfectionPercentage
from CovidProject..CovidDeaths
order by PopulationInfectionPercentage desc,location, date;

-- Searching countries with highest infection rate relative to population
select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PopulationInfectionPercentage
from CovidProject..CovidDeaths
group by location, population
order by PopulationInfectionPercentage desc;

-- Showing countries with highest death count per population
--had to cast it as an integer because it was formatted as a nonvariable character. This happens fairly often, remember that.
--this result includes continents and other groupings. When looking the data, the column 'continent' is null for the entries that are whole continents. Filtering it out will remove these aggregate results
select location, max(cast(total_deaths as int)) as TotalDeathCount
from CovidProject..CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc;

--Fleshing the DeathCount query above a bit more
select location, population, max(cast(total_deaths as int)) as TotalDeathCount, max(cast(total_deaths as int)/population)*100 as DeathCountPercentage
from CovidProject..CovidDeaths
where continent is not null
group by location, population
order by DeathCountPercentage desc;

-- BREAKING DATA DOWN PER CONTINENT

-- Discrepancy in this result. These results are excluding some countries as part of the continent totals
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from CovidProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc;

-- Other way to get the correct numbers. However that does include the income groups (easy fix with the where clause).
select location, max(cast(total_deaths as int)) as TotalDeathCount
from CovidProject..CovidDeaths
where continent is null and location not like '%income%'
group by location
order by TotalDeathCount desc;

--Verifying North America's numbers
select location, max(cast(total_deaths as int)) as TotalDeathCount
from CovidProject..CovidDeaths
where location in ('united states', 'canada', 'mexico')
group by location
order by TotalDeathCount desc; 

-- Ending here for the night. Next session, remember that you will need to use the continent query to get the accurate numbers you want for the visualisation.

-- Showing the continents with the highest death count per population

-- Other way to get the correct numbers. However that does include the income groups (easy fix with the where clause).
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from CovidProject..CovidDeaths
where continent is null and location not like '%income%'
group by continent
order by TotalDeathCount desc;



-- GLOBAL NUMBERS

--Looking at the total amount of new cases and deaths by date on a global scale
select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as GlobalDeathPercentage
from CovidProject..CovidDeaths
--where location like '%states%'
where continent is not null
group by date
order by 1,2;

-- Removing the date filter, summarizing total global cases, deaths, and the percentage of deaths
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as GlobalDeathPercentage
from CovidProject..CovidDeaths
--where location like '%states%'
where continent is not null
--group by date
order by 1,2;

-- Comparing Total Population vs Vaccinations
-- Had to use bigint because sum might have exceeded maximum int
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidProject..CovidDeaths dea
join CovidProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using CTE so we can use RollingPeopleVaccinated to perform further calculations. 
-- In this case, percentage of people vaccinated relative to population.
-- remember: If #E of columns in CTE is different from column in the query, you get an error. Also order by can't be in there
with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidProject..CovidDeaths dea
join CovidProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/Population)*100 as RollingVaccinationPercentage
from PopvsVac

-- This is to test above query with total numbers, by country
-- Interestingly, Vaccination % for almost a quarter of countries is over 100. Might be a discrepancy in how it's reported, such as 
-- counting multiple shots for each individyal (such as booster doses, etc)? 
-- also this data would be great for a visualization, showing the countries with vaccination % over a world map, and see how the continents compare as a whole
-- (wondering how South America compares to Europe for example)
with PopvsVac (Continent, Location, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.population, vac.new_vaccinations, 
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location) as RollingPeopleVaccinated
from CovidProject..CovidDeaths dea
join CovidProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select Location, Continent, Population, max(RollingPeopleVaccinated) as 'Total Vaccinations', (RollingPeopleVaccinated/Population)*100 as 'Total Vaccination Percentage'
from PopvsVac
group by location, continent, population, RollingPeopleVaccinated
--order by RollingVaccinationPercentage desc

--incorrect way of looking for the same results, as this is too broad and some countries will show up duplicated anyways
--select distinct Location, Continent, Population, RollingPeopleVaccinated, (RollingPeopleVaccinated/Population)*100 as RollingVaccinationPercentage
--from PopvsVac


-- TEMP TABLE
-- Just an alternative way of getting the same info done

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)


insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidProject..CovidDeaths dea
join CovidProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

select *, (RollingPeopleVaccinated/Population)*100 as RollingVaccinationPercentage
from #PercentPopulationVaccinated



--Creating view to store data for later visualizations
--drop view PercentPopulationVaccinated
create view PercentPopulationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidProject..CovidDeaths dea
join CovidProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3



-- Used for Tableau visualization

--1. Global cases/deaths

--Looking at the total amount of new cases and deaths by date on a global scale
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as GlobalDeathPercentage
from CovidProject..CovidDeaths
--where location like '%states%'
where continent is not null
--group by date
order by 1,2;

--2. Total death count per continent

select location, sum(cast(new_deaths as int)) as TotalDeathCount
from CovidProject..CovidDeaths
--where location like '%states%'
where continent is null
and location not in ('World', 'European Union', 'International')
and location not like '%income%'
group by location
order by TotalDeathCount desc;

--3. Total COVID cases per country and percentage of their population that got infected

select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

--4. Total COVID cases per country and percentage of their population that got infected, this time sorted by date

select Location, Population, date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc

-- Will play with more visualizations and upload them later, lots to be discovered from this dataset

