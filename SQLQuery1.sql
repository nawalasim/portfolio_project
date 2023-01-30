SELECT location,date,total_cases,total_deaths,population
FROM portfolio_project..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2

--looking at total cases vs total deaths
--shows the likelihood of dying if contracting COVID in a particular region
SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as ratio
FROM portfolio_project..CovidDeaths$
WHERE location = 'Pakistan' 
ORDER BY 1,2

--Looking at the total cases vs population
--shows what percentage of population got covid
--Looking at stats for Pakistan rn
SELECT location,date,total_cases,population,(total_cases/population)*100 as ratio
FROM portfolio_project..CovidDeaths$
WHERE location = 'Pakistan'
ORDER BY 1,2

--what country has highest infection rate
SELECT location,population, max(total_cases) as highest_infection_count, (max(total_cases)/population)*100 as percent_population_infected
FROM portfolio_project..CovidDeaths$
GROUP BY location, population
ORDER BY percent_population_infected DESC

--Showing countries with highest death count per population
SELECT location, max(cast(total_deaths as int)) as highest_death_count, (max(cast(total_deaths as int))/population)*100 as death_rate
FROM portfolio_project..CovidDeaths$
WHERE continent is not null
GROUP BY location, population
ORDER BY death_rate DESC

--Showing the continents with the highest death count per population
SELECT location, max(cast(total_deaths as int)) as highest_death_count,
max(cast(total_deaths as int))/population as death_rate
FROM portfolio_project..CovidDeaths$
WHERE continent is  null
GROUP BY location, population
ORDER BY death_rate DESC


--Global numbers
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as Death_percentage
FROM portfolio_project..CovidDeaths$
WHERE continent IS NOT null
GROUP BY date
order by 1,2 

--vaccination vs populations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM portfolio_project..CovidDeaths$ dea
JOIN portfolio_project..CovidVaccinations$ vac
ON dea.date=vac.date
and dea.location=vac.location
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Running total of new vaccinations using Windows Functions
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int))OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date)
as rolling_vaccintation
FROM portfolio_project..CovidDeaths$ dea
JOIN portfolio_project..CovidVaccinations$ vac
ON dea.date=vac.date
and dea.location=vac.location
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--USING CTE
WITH PopVsVac(continent, location, date, population,new_vaccinations, rolling_vaccination)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int))OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date)
as rolling_vaccintation
FROM portfolio_project..CovidDeaths$ dea
JOIN portfolio_project..CovidVaccinations$ vac
ON dea.date=vac.date
and dea.location=vac.location
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_vaccination/Population)*100
FROM PopVsVac


--TEMP TABLE
--Usin drop function so table is easy to alter if needed
DROP table if exists Percent_pop_vaccinated
Create Table Percent_pop_vaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
Population numeric,
new_vaccinations numeric,
rolling_vaccination numeric
)
Insert into Percent_pop_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int))OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date)
as rolling_vaccintation
FROM portfolio_project..CovidDeaths$ dea
JOIN portfolio_project..CovidVaccinations$ vac
ON dea.date=vac.date
and dea.location=vac.location
WHERE dea.continent IS NOT NULL

SELECT *, (rolling_vaccination/Population)*100
FROM Percent_pop_vaccinated

--Creating view to store data for later visualizations

Create View Percentpopview as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int))OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date)
as rolling_vaccintation
FROM portfolio_project..CovidDeaths$ dea
JOIN portfolio_project..CovidVaccinations$ vac
ON dea.date=vac.date
and dea.location=vac.location
WHERE dea.continent IS NOT NULL

SELECT *
FROM Percentpopview