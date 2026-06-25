import '../models/reward.dart';

/// Starter rewards for new parents — editable and deletable like any reward.
abstract final class DefaultRewardsCatalog {
  /// Kids earn 10 points per brushing session (max 2/day).
  static List<Reward> rewards() => [
        const Reward(
          id: 'default_candy',
          name: 'Candy',
          pointsRequired: 30,
          price: 3,
        ),
        const Reward(
          id: 'default_extra_screen_time',
          name: 'Extra Screen Time',
          pointsRequired: 40,
          price: 0,
        ),
        const Reward(
          id: 'default_choose_dinner',
          name: 'Choose Dinner',
          pointsRequired: 50,
          price: 0,
        ),
        const Reward(
          id: 'default_ice_cream_trip',
          name: 'Ice Cream Trip',
          pointsRequired: 50,
          price: 8,
        ),
        const Reward(
          id: 'default_pool_time',
          name: 'Pool Time',
          pointsRequired: 60,
          price: 0,
        ),
        const Reward(
          id: 'default_park_trip',
          name: 'Park Trip',
          pointsRequired: 60,
          price: 0,
        ),
        const Reward(
          id: 'default_stay_up_late',
          name: 'Stay Up Late',
          pointsRequired: 70,
          price: 0,
        ),
        const Reward(
          id: 'default_bake_cookies',
          name: 'Bake Cookies Together',
          pointsRequired: 75,
          price: 10,
        ),
        const Reward(
          id: 'default_movie_night',
          name: 'Movie Night',
          pointsRequired: 80,
          price: 25,
        ),
        const Reward(
          id: 'default_toy_shopping',
          name: 'Toy Shopping',
          pointsRequired: 100,
          price: 25,
        ),
        const Reward(
          id: 'default_money',
          name: 'Money',
          pointsRequired: 100,
          price: 10,
        ),
        const Reward(
          id: 'default_sleepover',
          name: 'Sleepover',
          pointsRequired: 120,
          price: 30,
        ),
        const Reward(
          id: 'default_new_video_game',
          name: 'New Video Game',
          pointsRequired: 150,
          price: 60,
        ),
      ];
}
