import { useState, useEffect } from "react";
import { useNavigate, Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/integrations/supabase/client";
import { User } from "@supabase/supabase-js";
import NavigationBar from "@/components/NavigationBar";
import { useUserProducts } from "@/hooks/useUserProducts";
import { useUserSavedProducts } from "@/hooks/useUserSavedProducts";
import { useUnreadMessagesCount } from "@/hooks/useUnreadMessagesCount";

interface Profile {
  id: string;
  user_id: string;
  email: string;
  first_name: string | null;
  last_name: string | null;
  nickname: string | null;
  created_at: string;
  updated_at: string;
}

const Profile = () => {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  const [editingNickname, setEditingNickname] = useState(false);
  const [nicknameInput, setNicknameInput] = useState("");
  const [savingNickname, setSavingNickname] = useState(false);
  const navigate = useNavigate();
  const { toast } = useToast();

  const { products: userProducts } = useUserProducts();
  const { products: savedProducts } = useUserSavedProducts();
  const { unreadCount } = useUnreadMessagesCount();

  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_, session) => {
        setUser(session?.user ?? null);
        if (!session?.user) {
          navigate("/auth");
        } else {
          setTimeout(() => {
            fetchProfile(session.user.id);
          }, 0);
        }
      }
    );

    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      if (!session?.user) {
        navigate("/auth");
      } else {
        fetchProfile(session.user.id);
      }
    });

    return () => subscription.unsubscribe();
  }, [navigate]);

  const fetchProfile = async (userId: string) => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();

      if (error) {
        console.error('Error fetching profile:', error);
        toast({
          title: "Error",
          description: "Failed to load profile information.",
          variant: "destructive",
        });
      } else {
        setProfile(data);
      }
    } catch (error) {
      console.error('Error:', error);
      toast({
        title: "Error",
        description: "An unexpected error occurred.",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleEditNickname = () => {
    setNicknameInput(profile?.nickname ?? "");
    setEditingNickname(true);
  };

  const handleCancelNickname = () => {
    setEditingNickname(false);
    setNicknameInput("");
  };

  const handleSaveNickname = async () => {
    if (!user) return;
    setSavingNickname(true);
    try {
      const trimmed = nicknameInput.trim();
      const { error } = await supabase
        .from('profiles')
        .update({ nickname: trimmed || null })
        .eq('user_id', user.id);

      if (error) {
        toast({
          title: "Error",
          description: "Failed to save nickname.",
          variant: "destructive",
        });
      } else {
        setProfile(prev => prev ? { ...prev, nickname: trimmed || null } : prev);
        setEditingNickname(false);
        toast({ title: "Nickname updated" });
      }
    } catch {
      toast({
        title: "Error",
        description: "An unexpected error occurred.",
        variant: "destructive",
      });
    } finally {
      setSavingNickname(false);
    }
  };

  const handleSignOut = async () => {
    try {
      setUser(null);
      setProfile(null);
      for (const key in localStorage) {
        if (key.startsWith('supabase.auth.') || key.includes('supabase')) {
          localStorage.removeItem(key);
        }
      }
      try {
        await supabase.auth.signOut();
      } catch (signOutError) {
        console.log('Sign out API call failed, but local session was cleared:', signOutError);
      }
      toast({
        title: "Signed out",
        description: "You have been successfully signed out.",
      });
      setTimeout(() => {
        window.location.href = '/';
      }, 100);
    } catch (error) {
      console.error('Sign out error:', error);
      toast({
        title: "Error",
        description: "An unexpected error occurred.",
        variant: "destructive",
      });
    }
  };

  const defaultNickname = profile?.first_name && profile?.last_name
    ? `${profile.first_name} ${profile.last_name}`
    : null;

  if (loading) {
    return (
      <div className="min-h-screen bg-background font-orator">
        <NavigationBar />
        <div className="flex items-center justify-center pt-20">
          <div className="text-foreground">Loading...</div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background font-orator">
      <NavigationBar />

      <div className="px-4 py-4">
        <h1 className="text-lg font-medium text-foreground mb-3">Account</h1>

        {/* Profile Information Card */}
        <div className="bg-card border border-foreground/15 rounded-[14px] p-5 mb-4">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-base font-medium text-foreground">Profile information</h2>
          </div>

          <div className="space-y-3">
            <div>
              <div className="text-sm font-medium text-foreground mb-1">Name</div>
              <div className="text-foreground">
                {defaultNickname ?? "Unable to fetch data"}
              </div>
            </div>

            {/* Nickname field */}
            <div>
              <div className="text-sm font-medium text-foreground mb-1">Nickname</div>
              {editingNickname ? (
                <div className="flex items-center gap-2">
                  <Input
                    value={nicknameInput}
                    onChange={e => setNicknameInput(e.target.value)}
                    placeholder={defaultNickname ?? "Enter nickname"}
                    className="h-9 text-sm"
                    maxLength={50}
                    autoFocus
                    onKeyDown={e => {
                      if (e.key === 'Enter') handleSaveNickname();
                      if (e.key === 'Escape') handleCancelNickname();
                    }}
                  />
                  <Button
                    onClick={handleSaveNickname}
                    disabled={savingNickname}
                    className="h-9 px-4 text-sm bg-secondary text-secondary-foreground hover:bg-secondary/90 rounded-[20px]"
                  >
                    Save
                  </Button>
                  <Button
                    onClick={handleCancelNickname}
                    variant="ghost"
                    className="h-9 px-3 text-sm"
                  >
                    Cancel
                  </Button>
                </div>
              ) : (
                <div className="flex items-center gap-3">
                  <span className="text-foreground">
                    {profile?.nickname || defaultNickname || "Not set"}
                  </span>
                  <button
                    onClick={handleEditNickname}
                    className="text-sm text-foreground underline hover:no-underline min-h-[44px] inline-flex items-center"
                  >
                    Edit
                  </button>
                </div>
              )}
              <div className="text-xs text-foreground/50 mt-1">
                Displayed to other users as your seller or buyer name
              </div>
            </div>

            <div>
              <div className="text-sm font-medium text-foreground mb-1">E-mail</div>
              <div className="text-foreground">
                {profile?.email || "Unable to fetch data"}
              </div>
            </div>

            <div>
              <div className="text-sm font-medium text-foreground mb-1">Password</div>
              <div className="text-foreground">**********</div>
            </div>
          </div>
        </div>

        {/* Activity Card */}
        <div className="bg-card border border-foreground/15 rounded-[14px] p-5 mb-8">
          <h2 className="text-base font-medium text-foreground mb-4">Activity</h2>

          <div className="space-y-3">
            <div>
              <div className="text-foreground mb-1">You have ({userProducts.length}) listings</div>
              <Link to="/create-listing" className="text-foreground underline hover:no-underline min-h-[44px] min-w-[44px] inline-flex items-center">
                View listings
              </Link>
            </div>

            <div>
              <div className="text-foreground mb-1">You have ({unreadCount}) unread messages</div>
              <Link to="/messages" className="text-foreground underline hover:no-underline min-h-[44px] min-w-[44px] inline-flex items-center">
                View messages
              </Link>
            </div>

            <div>
              <div className="text-foreground mb-1">You have ({savedProducts.length}) saved products</div>
              <Link to="/saved-items" className="text-foreground underline hover:no-underline min-h-[44px] min-w-[44px] inline-flex items-center">
                View all saved products
              </Link>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex flex-col items-center gap-4 pb-8">
          <Link to="/">
            <Button
              className="bg-secondary text-secondary-foreground hover:bg-secondary/90 h-[46px] px-8 rounded-[20px] min-h-[44px] min-w-[44px]"
            >
              Return Home
            </Button>
          </Link>

          <Button
            onClick={handleSignOut}
            className="bg-secondary text-secondary-foreground hover:bg-secondary/90 h-[46px] px-8 rounded-[20px] min-h-[44px] min-w-[44px]"
          >
            Sign Out
          </Button>
        </div>
      </div>
    </div>
  );
};

export default Profile;
