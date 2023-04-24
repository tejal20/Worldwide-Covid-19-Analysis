-- Prelimnary data exploration

USE ProjectDB
SELECT * FROM CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1, 2

-- Country wise percentage of death if diagnosed with Covid
SELECT location, date, total_cases, total_deaths, population, (CAST(total_deaths as float) / CAST(total_cases as float))*100 as Death_Percentage
FROM CovidDeaths
WHERE location LIKE '%india%' AND continent IS NOT NULL
ORDER BY 1, 2

-- Total cases vs the population
SELECT location, date, population, total_cases, (CAST(total_cases as float) / CAST(population as float))*100 as Percent_of_Total_Cases
FROM CovidDeaths
WHERE continent is NOT NULL
--WHERE location LIKE '%india%'
ORDER BY 1, 2

-- Countries with highest infection rate
SELECT location, population, MAX(total_cases) as Highest_infection_count, MAX(CAST(total_cases as float) / CAST(population as float))*100 as Percent_of_Total_Cases
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

-- Countries with highest Death rate
SELECT location, MAX(CAST(total_deaths as int)) as Highest_Death_Count
FROM CovidDeaths
WHERE continent is  NULL
GROUP BY location
ORDER BY 2 DESC

-- Highest Death rates by continent
SELECT continent, MAX(CAST(total_deaths as int)) as Highest_Death_Count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

-- Global numbers on new cases and new deaths
SELECT SUM(new_cases) as Total_New_Cases, SUM(new_deaths) as Total_New_Deaths, SUM(new_deaths)/ SUM(new_cases) * 100 as New_Cases_Death_Percentage
FROM CovidDeaths
-- WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1, 2 

-- Total population vs total vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinatedSum
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

WITH PopulationVsVaccination (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinateSum)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinatedSum
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
Select *, (RollingVaccinateSum / Population) * 100
FROM PopulationVsVaccination

-- Temp table
CREATE TABLE #PercentOfPopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinateSum numeric
)

INSERT INTO #PercentOfPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinatedSum
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (RollingVaccinateSum / Population) * 100
FROM #PercentOfPopulationVaccinated

DROP TABLE #PercentOfPopulationVaccinated

-- Creating views
CREATE VIEW PercentOfPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingVaccinatedSum
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * FROM PercentOfPopulationVaccinated

-- Creating tables to import data in Tableau
-- Table 1
CREATE TABLE DeathPercentage
(
Total_Cases numeric,
Total_Deaths numeric,
Percentage float,
)
INSERT INTO DeathPercentage
SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM CovidDeaths
--Where location like '%states%'
WHERE continent is not null 
--Group By date
ORDER BY 1,2

SELECT * FROM DeathPercentage

-- Table 2
CREATE TABLE TotalDeaths
(
Location nvarchar(255),
Total_Deaths numeric,
)
INSERT INTO TotalDeaths
SELECT location, SUM(CAST(new_deaths as int)) as TotalDeathCount
FROM CovidDeaths
--Where location like '%states%'
WHERE continent is null 
AND location NOT IN ('World', 'European Union', 'International', 'Low income', 'Upper middle income', 'High income', 'Lower middle income')
GROUP BY location
ORDER BY TotalDeathCount DESC

SELECT * FROM TotalDeaths

-- Table 3
CREATE TABLE InfectedPopulation
(
Location nvarchar(255), 
Population numeric,
HighestInfectionCount numeric,
InfectedPercentage float 
)
INSERT INTO InfectedPopulation
SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 as PercentPopulationInfected
FROM CovidDeaths
--Where location like '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc

SELECT * FROM InfectedPopulation

UPDATE InfectedPopulation
SET HighestInfectionCount = 0
WHERE HighestInfectionCount IS NULL 

UPDATE InfectedPopulation
SET InfectedPercentage = 0
WHERE InfectedPercentage IS NULL 


-- Table 4
CREATE TABLE InfectedPopulationByDate
( 
Location nvarchar(255),
Population numeric,
Date datetime,
HighestInfectionCount numeric,
PercentPopulationInfected float
)
INSERT INTO InfectedPopulationByDate
SELECT Location, Population,date, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 as PercentPopulationInfected
FROM CovidDeaths
--Where location like '%states%'
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected desc

UPDATE InfectedPopulationByDate
SET HighestInfectionCount = 0
WHERE HighestInfectionCount IS NULL 

UPDATE InfectedPopulationByDate
SET PercentPopulationInfected = 0
WHERE PercentPopulationInfected IS NULL 

SELECT * FROM InfectedPopulationByDate 