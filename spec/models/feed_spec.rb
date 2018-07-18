RSpec.describe Feed do
  describe 'registering a feed' do
    let(:attrs) { { url: 'https://example.com/feed.json' } }
    subject { Feed.register(attrs) }

    context 'when the feed has not been registered before' do
      it 'creates a new feed' do
        expect { subject }.to change { Feed.count }.by 1
      end

      it 'returns the created feed' do
        expect(subject).to be_a Feed
        expect(subject.url).to eq 'https://example.com/feed.json'
      end

      it 'sets timestamps on the created feed' do
        expect(subject.created_at).not_to be_nil
        expect(subject.updated_at).not_to be_nil
        expect(subject.refreshed_at).to be_nil
      end
    end

    context 'when the feed has been registered before' do
      let!(:existing) { Feed.register(attrs) }

      it 'does not create a new feed' do
        expect { subject }.not_to(change { Feed.count })
      end

      it 'returns the existing feed' do
        expect(subject).to eq existing
      end
    end
  end
end
