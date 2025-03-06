Select *
From ProjectPortfolio_db.coviddeaths
Where continent is not null 
order by 3,4;

-- Select *
-- From ProjectPortfolio_db.coviddeaths
-- Order by 3,4

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From ProjectPortfolio_db.coviddeaths
Where continent is not null
Order by 1, 2;

-- Looking at the Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your Country

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From ProjectPortfolio_db.coviddeaths
Where Location like'%canada%'
and continent is not null
Order by 1, 2;

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

Select Location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From ProjectPortfolio_db.coviddeaths
-- Where Location like'%canada%'
Order by 1, 2;


-- Looking at Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From ProjectPortfolio_db.coviddeaths
-- Where Location like '%Canada%'
Group by Location, Population
Order by PercentPopulationInfected desc;


-- Showing Countries with Highest Death Count Per Population

Select 
    Location, 
    MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
From ProjectPortfolio_db.coviddeaths
Where total_deaths REGEXP '^[0-9]+$' -- Ensures only numeric values are considered
And continent is not NULL 
Group by Location
Order by TotalDeathCount DESC;


-- LET'S BREAK THINGS DOWN BY CONTINENT

--  Showing continents with the highest death count  per population

Select 
    continent, 
    MAX(CAST(total_deaths AS float)) AS TotalDeathCount
From ProjectPortfolio_db.coviddeaths
Where continent is NOT NULL 
Group by continent
Order by TotalDeathCount DESC;

-- GLOBAL NUMBERS

Select 
	date, 
    SUM(new_cases) as total_cases, 
    SUM(cast(new_deaths as float)) as total_deaths, 
    SUM(cast(new_deaths as float))/SUM(new_cases)*100 as DeathPercentage
From 
	ProjectPortfolio_db.coviddeaths
where 
	continent is not null 
Group by date
order by 1, 2;


Select 
    SUM(new_cases) as total_cases, 
    SUM(cast(new_deaths as float)) as total_deaths, 
    SUM(cast(new_deaths as float))/SUM(new_cases)*100 as DeathPercentage
From 
	ProjectPortfolio_db.coviddeaths
where 
	continent is not null 
order by 1, 2;

-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
From ProjectPortfolio_db.coviddeaths dea
Join ProjectPortfolio_db.covidvaccination vac
	On dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
order by 2, 3;



Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as float)) OVER (partition by dea.location Order by dea.location, dea.date) 
    as RollingPeopleVaccinated
From ProjectPortfolio_db.coviddeaths dea
Join ProjectPortfolio_db.covidvaccination vac
	On dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
order by 2, 3;



-- USE CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as float)) OVER (partition by dea.location Order by dea.location, dea.date) 
    as RollingPeopleVaccinated
From ProjectPortfolio_db.coviddeaths dea
Join ProjectPortfolio_db.covidvaccination vac
	On dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
-- order by 2, 3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac;


-- TEMP TABLE
-- Drop the table if it already exists
DROP TABLE IF EXISTS PercentPopulationVaccinated;

-- Create a table to store vaccination data
CREATE TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATETIME,
    Population DECIMAL(20,2),
    New_Vaccinations DECIMAL(20,2),
    RollingPeopleVaccinated DECIMAL(20,2)
);

-- Insert data into the table
INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    -- Ensure the column is numeric, replace NULL with 0
    COALESCE(NULLIF(vac.new_vaccinations, ''), 0) AS New_Vaccinations,
    -- Use DECIMAL instead of FLOAT
    SUM(CAST(COALESCE(NULLIF(vac.new_vaccinations, ''), 0) AS DECIMAL(20,2))) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) 
    AS RollingPeopleVaccinated
FROM 
    ProjectPortfolio_db.coviddeaths dea
JOIN 
    ProjectPortfolio_db.covidvaccination vac
ON 
    dea.location = vac.location
AND 
    dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;

-- Retrieve the results
SELECT *, 
       (RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;


-- Creating View to store data for later visualizations
-- Drop the table if it already exists
DROP TABLE IF EXISTS PercentPopulationVaccinated;

Create View PercentPopulationVaccinated as
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    -- Ensure the column is numeric, replace NULL with 0
    COALESCE(NULLIF(vac.new_vaccinations, ''), 0) AS New_Vaccinations,
    -- Use DECIMAL instead of FLOAT
    SUM(CAST(COALESCE(NULLIF(vac.new_vaccinations, ''), 0) AS DECIMAL(20,2))) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) 
    AS RollingPeopleVaccinated
FROM 
    ProjectPortfolio_db.coviddeaths dea
JOIN 
    ProjectPortfolio_db.covidvaccination vac
ON 
    dea.location = vac.location
AND 
    dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;

