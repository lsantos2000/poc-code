using SuperHeroApiDotNet7.Data;
using SuperHeroApiDotNet7.Models;

namespace SuperHeroApiDotNet7.Services.SuperHeroService
{
    public class UserService : IUserService
    {
        private readonly DataContext _context;

        public UserService(DataContext context)
        {
            _context = context;
        }

        public async Task<List<User>> AddHero(User user)
        {
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            return await _context.Users.ToListAsync();
        }

        public Task<List<User>> AddUser(User user)
        {
            throw new NotImplementedException();
        }

        public async Task<List<User>?> DeleteUser(int id)
        {
            var hero = await _context.Users.FindAsync(id);
            if (hero is null)
                return null;

            _context.Users.Remove(hero);
            await _context.SaveChangesAsync();

            return await _context.Users.ToListAsync();
        }


        public async Task<List<User>> GetAllUsers()
        {
            var users = await _context.Users.ToListAsync();
            return users;
        }


        public async Task<User?> GetSingleUser(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user is null)
                return null;

            return user;
        }

        public async Task<List<User>?> UpdateUser(int id, User request)
        {
            var user = await _context.Users.FindAsync(id);
            if (user is null)
                return null;

            user.Name = request.Name;
            user.Email = request.Email;
            user.Phone = request.Phone;

            await _context.SaveChangesAsync();

            return await _context.Users.ToListAsync();
        }

    }
}
