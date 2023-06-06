using Microsoft.AspNetCore.Mvc;
using SuperHeroApiDotNet7.Services.SuperHeroService;

namespace SuperHeroApiDotNet7.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SuperHeroController : ControllerBase
    {
        private readonly ISuperHeroService _superHeroService;

        private static readonly List<SuperHero> _superHeroes = new List<SuperHero> {
            new SuperHero {
                Id = 1,
                Name =  "Spider Man",
                FirstName  = "Peter",
                LastName= "Parker",
                Place = "New York City"
            },
            new SuperHero {
                Id = 1,
                Name =  "Spider Man 2",
                FirstName  = "Peter2",
                LastName= "Parker2",
                Place = "New York City2"
            }
        };


        public SuperHeroController(ISuperHeroService superHeroService)
        {
            _superHeroService = superHeroService;
        }

        [HttpGet]
        public async Task<ActionResult<List<SuperHero>>> GetAllHeroes()
        {
            return await _superHeroService.GetAllHeroes();
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<SuperHero>> GetSingleHero(int id)
        {
            var result = await _superHeroService.GetSingleHero(id);
            if (result is null)
                return NotFound("Hero not found.");

            return Ok(result);
        }

        [HttpPost]
        public async Task<ActionResult<List<SuperHero>>> AddHero(SuperHero hero)
        {
            var result = await _superHeroService.AddHero(hero);
            return Ok(result);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<List<SuperHero>>> UpdateHero(int id, SuperHero request)
        {
            var result = await _superHeroService.UpdateHero(id, request);
            if (result is null)
                return NotFound("Hero not found.");

            return Ok(result);
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult<List<SuperHero>>> DeleteHero(int id)
        {
            var result = await _superHeroService.DeleteHero(id);
            if (result is null)
                return NotFound("Hero not found.");

            return Ok(result);
        }

        /*

        // *FromList methods are using just the readonly list 
        [HttpGet]
        public async Task<ActionResult<List<SuperHero>>> GetAllHeroesFromList()
        {
            return Ok(_superHeroes);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<SuperHero>> GetSingleHeroFromList(int id)
        {
            var result = _superHeroes.Find(x => x.Id == id);
            if (result is null)
                return NotFound("Hero not found.");

            return Ok(result);
        }

        [HttpPost]
        public async Task<ActionResult<SuperHero>> AddHeroFromList(SuperHero hero)
        {
            _superHeroes.Add(hero);
             return Ok(_superHeroes);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<SuperHero>>UpdateHeroFromList(int id, SuperHero request)
        {
            var hero = _superHeroes.Find(x => x.Id == id);
            if (hero is null)
                return NotFound("Hero not found.");

            hero.FirstName = request.FirstName;
            hero.LastName = request.LastName;
            hero.Name = request.Name;
            hero.Place = request.Place;

            return Ok(_superHeroes);
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult<List<SuperHero>>> DeleteHeroFromList(int id)
        {
            var hero = _superHeroes.Find(x => x.Id == id);
            if (hero is null)
                return NotFound("Hero not found.");

            _superHeroes.Remove(hero);

            return Ok(_superHeroes);
        }
        */

    }
}
