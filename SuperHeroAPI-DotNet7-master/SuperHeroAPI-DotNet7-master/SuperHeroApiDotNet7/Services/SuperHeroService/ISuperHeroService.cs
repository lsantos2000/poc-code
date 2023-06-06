namespace SuperHeroApiDotNet7.Services.SuperHeroService
{
    public interface ISuperHeroService
    {
        Task<List<SuperHero>> GetAllHeroes();
        Task<SuperHero?> GetSingleHero(int id);
        Task<List<SuperHero>> AddHero(SuperHero hero);
        Task<List<SuperHero>?> UpdateHero(int id, SuperHero request);
        Task<List<SuperHero>?> DeleteHero(int id);

        /*
        // *FromList methods use the static list, not the database
        Task<List<SuperHero>> GetAllHeroesFromList();
        Task<SuperHero?> GetSingleHeroFromList(int id);
        Task<List<SuperHero>> AddHeroFromList(SuperHero hero);
        Task<List<SuperHero>?> UpdateHeroFromList(int id, SuperHero request);
        Task<List<SuperHero>?> DeleteHeroFromList(int id);
        */
    }
}
